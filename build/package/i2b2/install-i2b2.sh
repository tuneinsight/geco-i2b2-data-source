#!/usr/bin/env bash
set -Eeuo pipefail

JBOSS_HOME_DEPLOYMENTS="$JBOSS_HOME/standalone/deployments"

pushd "$SRC_DIR"
  pushd i2b2-core-server

    # patch i2b2 sources
    git apply "../patches/"*.diff

    pushd edu.harvard.i2b2.server-common

      # build i2b2 WAR from sources and copy war file
      sed -i "/jboss.home/c\jboss.home=$JBOSS_HOME" build.properties
      ant clean dist war
      cp dist/i2b2.war "$JBOSS_HOME_DEPLOYMENTS/i2b2.war.zip"

      # unpack i2b2 WAR
      pushd "$JBOSS_HOME_DEPLOYMENTS"
        mkdir i2b2.war
        unzip i2b2.war.zip -d i2b2.war
        rm i2b2.war.zip
        touch i2b2.war.dodeploy
      popd

      # copy additional libraries
      ant jboss_pre_deployment_setup
    popd
  popd

  # archive i2b2 data
  pushd i2b2-data
    rm -rf ./.git # remove git info to get a lighter image
    GZIP=-9 tar cvzf "$I2B2_DATA_ARCHIVE" -C . .
  popd

  # delete repositories to free up space
  rm -rf i2b2-core-server i2b2-data

popd
