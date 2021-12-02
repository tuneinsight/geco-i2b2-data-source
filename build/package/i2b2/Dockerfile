FROM jboss/wildfly:17.0.1.Final

# build-time variables
ENV I2B2_DATA_ARCHIVE="$JBOSS_HOME/standalone/data/i2b2-data.tar.gz" \
    I2B2_FR_FILES_DIR="$JBOSS_HOME/standalone/data/i2b2_FR_files" \
    I2B2_PASSWORD_HASH_TOOL="$JBOSS_HOME/standalone/data/I2b2PasswordHash" \
    SRC_DIR=/src

# needed packages and pre-requisites
USER root
RUN yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    yum update -y && yum -y install wget git ant postgresql13 && yum clean all && \
    mkdir -p "$SRC_DIR" "$I2B2_FR_FILES_DIR" "$I2B2_PASSWORD_HASH_TOOL" && chown -R jboss:jboss "$SRC_DIR" "$JBOSS_HOME"
USER jboss

# wildfly custom configuration
RUN sed -i 's/Xmx512m/Xmx2048m/g' "$JBOSS_HOME"/bin/standalone.conf && \
    sed -i 's/MaxMetaspaceSize=256m/MaxMetaspaceSize=1024m/g' "$JBOSS_HOME"/bin/standalone.conf

# download i2b2 sources
ARG I2B2_VERSION=tags/v1.7.12a.0002
ARG I2B2_DATA_VERSION=01488ff1367717fda2799809bc531384382d6a94
COPY --chown=jboss:jboss download-i2b2-sources.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/download-i2b2-sources.sh
RUN download-i2b2-sources.sh

# install i2b2
COPY --chown=jboss:jboss patches "$SRC_DIR/patches"
COPY --chown=jboss:jboss install-i2b2.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-i2b2.sh
RUN install-i2b2.sh

# install i2b2 password hasher
COPY --chown=jboss:jboss I2b2PasswordHash.java "$SRC_DIR/"
RUN javac -d "$I2B2_PASSWORD_HASH_TOOL" "$SRC_DIR/I2b2PasswordHash.java"

# run-time variables
ENV I2B2_DB_HOST="postgresql" \
    I2B2_DB_PORT="5432" \
    I2B2_DB_USER="i2b2" \
    I2B2_DB_PW="i2b2" \
    I2B2_DB_NAME="i2b2" \
    WILDFLY_ADMIN_PASSWORD="admin" \
    I2B2_DOMAIN_NAME="i2b2demo" \
    I2B2_SERVICE_PASSWORD="changeme" \
    DEFAULT_USER_PASSWORD="demouser" \
    AXIS2_LOGLEVEL="INFO"

COPY --chown=jboss:jboss pre-init-scripts "$SRC_DIR/pre-init-scripts"
COPY --chown=jboss:jboss sql "$SRC_DIR/sql"
COPY --chown=jboss:jboss docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
EXPOSE 8080 9990
ARG PG_JDBC_JAR=postgresql-42.2.8.jar
ENV PG_JDBC_JAR="$PG_JDBC_JAR"
ENTRYPOINT \
    I2B2_SQL_DIR="$SRC_DIR/sql" \
    PRE_INIT_SCRIPT_DIR="$SRC_DIR/pre-init-scripts" \
    docker-entrypoint.sh
