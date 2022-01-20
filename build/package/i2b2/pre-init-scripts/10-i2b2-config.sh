#!/bin/bash
set -Eeuo pipefail

# set i2b2 log level
pushd  "$JBOSS_HOME/standalone/deployments/i2b2.war/WEB-INF/classes"
sed -i "/^log4j.rootCategory=/c\log4j.rootCategory=$AXIS2_LOGLEVEL, CONSOLE" log4j.properties
popd
