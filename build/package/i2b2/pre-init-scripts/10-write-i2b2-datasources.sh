#!/bin/bash
set -Eeuo pipefail
# write all the wildfly data sources for the i2b2 cells

cat > "$JBOSS_HOME/standalone/deployments/pm-ds.xml" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<datasources xmlns="http://www.jboss.org/ironjacamar/schema">
    <datasource jta="false" jndi-name="java:/PMBootStrapDS"
            pool-name="PMBootStrapDS" enabled="true" use-ccm="false">
                <connection-url>jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$I2B2_DB_NAME?currentSchema=i2b2pm</connection-url>
                <driver-class>org.postgresql.Driver</driver-class>
                <driver>$PG_JDBC_JAR</driver>
                <security>
                        <user-name>$I2B2_DB_USER</user-name>
                        <password>$I2B2_DB_PW</password>
                </security>
                <validation>
                        <validate-on-match>false</validate-on-match>
                        <background-validation>false</background-validation>
                </validation>
                <statement>
                        <share-prepared-statements>false</share-prepared-statements>
                </statement>
        </datasource>
</datasources>
EOL

cat > "$JBOSS_HOME/standalone/deployments/ont-ds.xml" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<datasources xmlns="http://www.jboss.org/ironjacamar/schema">
    <datasource jta="false" jndi-name="java:/OntologyBootStrapDS"
                pool-name="OntologyBootStrapDS" enabled="true" use-ccm="false">
        <connection-url>jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$I2B2_DB_NAME?currentSchema=i2b2hive</connection-url>
        <driver-class>org.postgresql.Driver</driver-class>
        <driver>$PG_JDBC_JAR</driver>
        <security>
            <user-name>$I2B2_DB_USER</user-name>
            <password>$I2B2_DB_PW</password>
        </security>
        <validation>
            <validate-on-match>false</validate-on-match>
            <background-validation>false</background-validation>
        </validation>
        <statement>
            <share-prepared-statements>false</share-prepared-statements>
        </statement>
    </datasource>

    <datasource jta="false" jndi-name="java:/OntologyDemoDS"
                pool-name="OntologyDemoDS" enabled="true" use-ccm="false">
        <connection-url>jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$I2B2_DB_NAME?currentSchema=i2b2metadata</connection-url>
        <driver-class>org.postgresql.Driver</driver-class>
        <driver>$PG_JDBC_JAR</driver>
        <security>
            <user-name>$I2B2_DB_USER</user-name>
            <password>$I2B2_DB_PW</password>
        </security>
        <validation>
            <validate-on-match>false</validate-on-match>
            <background-validation>false</background-validation>
        </validation>
        <statement>
            <share-prepared-statements>false</share-prepared-statements>
        </statement>
    </datasource>
</datasources>

EOL

cat > "$JBOSS_HOME/standalone/deployments/crc-ds.xml" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<datasources xmlns="http://www.jboss.org/ironjacamar/schema">
        <datasource jta="false" jndi-name="java:/CRCBootStrapDS"
                pool-name="CRCBootStrapDS" enabled="true" use-ccm="false">
                <connection-url>jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$I2B2_DB_NAME?currentSchema=i2b2hive</connection-url>
                <driver-class>org.postgresql.Driver</driver-class>
                <driver>$PG_JDBC_JAR</driver>
                <security>
                        <user-name>$I2B2_DB_USER</user-name>
                        <password>$I2B2_DB_PW</password>
                </security>
                <validation>
                        <validate-on-match>false</validate-on-match>
                        <background-validation>false</background-validation>
                </validation>
                <statement>
                        <share-prepared-statements>false</share-prepared-statements>
                </statement>
        </datasource>

        <datasource jta="false" jndi-name="java:/QueryToolDemoDS"
                pool-name="QueryToolDemoDS" enabled="true" use-ccm="false">
                <connection-url>jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$I2B2_DB_NAME?currentSchema=i2b2demodata</connection-url>
                <driver-class>org.postgresql.Driver</driver-class>
                <driver>$PG_JDBC_JAR</driver>
                <security>
                        <user-name>$I2B2_DB_USER</user-name>
                        <password>$I2B2_DB_PW</password>
                </security>
                <validation>
                        <validate-on-match>false</validate-on-match>
                        <background-validation>false</background-validation>
                </validation>
                <statement>
                        <share-prepared-statements>false</share-prepared-statements>
                </statement>
        </datasource>
</datasources>
EOL

cat > "$JBOSS_HOME/standalone/deployments/work-ds.xml" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<datasources xmlns="http://www.jboss.org/ironjacamar/schema">
    <datasource jta="false" jndi-name="java:/WorkplaceBootStrapDS"
            pool-name="WorkplaceBootStrapDS" enabled="true" use-ccm="false">
            <connection-url>jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$I2B2_DB_NAME?currentSchema=i2b2hive</connection-url>
            <driver-class>org.postgresql.Driver</driver-class>
            <driver>$PG_JDBC_JAR</driver>
            <security>
                    <user-name>$I2B2_DB_USER</user-name>
                    <password>$I2B2_DB_PW</password>
            </security>
            <validation>
                    <validate-on-match>false</validate-on-match>
                    <background-validation>false</background-validation>
            </validation>
            <statement>
                    <share-prepared-statements>false</share-prepared-statements>
            </statement>
    </datasource>

    <datasource jta="false" jndi-name="java:/WorkplaceDemoDS"
            pool-name="WorkplaceDemoDS" enabled="true" use-ccm="false">
            <connection-url>jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$I2B2_DB_NAME?currentSchema=i2b2workdata</connection-url>
            <driver-class>org.postgresql.Driver</driver-class>
            <driver>$PG_JDBC_JAR</driver>
            <security>
                    <user-name>$I2B2_DB_USER</user-name>
                    <password>$I2B2_DB_PW</password>
            </security>
            <validation>
                    <validate-on-match>false</validate-on-match>
                    <background-validation>false</background-validation>
            </validation>
            <statement>
                    <share-prepared-statements>false</share-prepared-statements>
            </statement>
    </datasource>
</datasources>
EOL
