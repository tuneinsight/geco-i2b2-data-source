#!/bin/bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
# load the structure and data of i2b2 database (including some bug fixes)

function loadI2b2Data {
    DB_NAME="$1"
    IS_ADDITIONAL_DB="$2"
    LOAD_DEMO_DATA="$3"

    # ---------- CRC data ----------
    cd "$I2B2_DATA_DIR/edu.harvard.i2b2.data/Release_1-7/NewInstall/Crcdata"

    cat > db.properties <<EOL
        db.type=postgresql
        db.username=$I2B2_DB_USER
        db.password=$I2B2_DB_PW
        db.driver=org.postgresql.Driver
        db.url=jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$DB_NAME?currentSchema=i2b2demodata
        db.project=demo
EOL

    ant -f data_build.xml create_crcdata_tables_release_1-7
    ant -f data_build.xml create_procedures_release_1-7

    if ! ${IS_ADDITIONAL_DB}
    then
          if ${LOAD_DEMO_DATA}
          then
              ant -f data_build.xml db_demodata_load_data
          fi
    fi


    # ---------- Hive data ----------
    cd "$I2B2_DATA_DIR/edu.harvard.i2b2.data/Release_1-7/NewInstall/Hivedata"

    cat > db.properties <<EOL
        db.type=postgresql
        db.username=$I2B2_DB_USER
        db.password=$I2B2_DB_PW
        db.driver=org.postgresql.Driver
        db.url=jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$DB_NAME?currentSchema=i2b2hive
EOL

    if ! ${IS_ADDITIONAL_DB}
    then
        ant -f data_build.xml create_hivedata_tables_release_1-7
        ant -f data_build.xml db_hivedata_load_data
    fi


    # ---------- IM data ----------
    cd "$I2B2_DATA_DIR/edu.harvard.i2b2.data/Release_1-7/NewInstall/Imdata"

    cat > db.properties <<EOL
        db.type=postgresql
        db.username=$I2B2_DB_USER
        db.password=$I2B2_DB_PW
        db.driver=org.postgresql.Driver
        db.url=jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$DB_NAME?currentSchema=i2b2imdata
        db.project=demo
EOL

    ant -f data_build.xml create_imdata_tables_release_1-7

    if ! ${IS_ADDITIONAL_DB}
    then
        if ${LOAD_DEMO_DATA}
        then
            ant -f data_build.xml db_imdata_load_data
        fi
    fi


    # ---------- Metadata ----------
    cd "$I2B2_DATA_DIR/edu.harvard.i2b2.data/Release_1-7/NewInstall/Metadata"

    cat > db.properties <<EOL
        db.type=postgresql
        db.username=$I2B2_DB_USER
        db.password=$I2B2_DB_PW
        db.driver=org.postgresql.Driver
        db.url=jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$DB_NAME?currentSchema=i2b2metadata
        db.project=demo
EOL

    ant -f data_build.xml create_metadata_tables_release_1-7

    if ! ${IS_ADDITIONAL_DB}
    then
        if ${LOAD_DEMO_DATA}
        then
            ant -f data_build.xml db_metadata_load_data
            #ant -f data_build.xml db_metadata_load_identified_data
        fi
    fi


    # ---------- PM data ----------
    cd "$I2B2_DATA_DIR/edu.harvard.i2b2.data/Release_1-7/NewInstall/Pmdata"

    cat > db.properties <<EOL
        db.type=postgresql
        db.username=$I2B2_DB_USER
        db.password=$I2B2_DB_PW
        db.driver=org.postgresql.Driver
        db.url=jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$DB_NAME?currentSchema=i2b2pm
        db.project=demo
EOL

    if ! ${IS_ADDITIONAL_DB}
    then
        ant -f data_build.xml create_pmdata_tables_release_1-7
        ant -f data_build.xml create_triggers_release_1-7
        ant -f data_build.xml db_pmdata_load_data
    fi


    # ---------- Work data ----------
    cd "$I2B2_DATA_DIR/edu.harvard.i2b2.data/Release_1-7/NewInstall/Workdata"

    cat > db.properties <<EOL
        db.type=postgresql
        db.username=$I2B2_DB_USER
        db.password=$I2B2_DB_PW
        db.driver=org.postgresql.Driver
        db.url=jdbc:postgresql://$I2B2_DB_HOST:$I2B2_DB_PORT/$DB_NAME?currentSchema=i2b2workdata
        db.project=demo
EOL

    ant -f data_build.xml create_workdata_tables_release_1-7
    ant -f data_build.xml db_workdata_load_data


    # ---------- Data bug fixes ----------
    if ! ${IS_ADDITIONAL_DB}
    then
        psql $PSQL_PARAMS -d "$DB_NAME" <<-EOSQL
            update i2b2hive.crc_db_lookup set c_db_fullschema = 'i2b2demodata' where c_domain_id = 'i2b2demo';
            update i2b2hive.im_db_lookup set c_db_fullschema = 'i2b2imdata' where c_domain_id = 'i2b2demo';
            update i2b2hive.ont_db_lookup set c_db_fullschema = 'i2b2metadata' where c_domain_id = 'i2b2demo';
            update i2b2hive.work_db_lookup set c_db_fullschema = 'i2b2workdata' where c_domain_id = 'i2b2demo';
EOSQL
    fi
}

# create schemas
initI2b2Schema "$I2B2_DB_NAME" i2b2demodata
initI2b2Schema "$I2B2_DB_NAME" i2b2imdata
initI2b2Schema "$I2B2_DB_NAME" i2b2metadata
initI2b2Schema "$I2B2_DB_NAME" i2b2workdata
initI2b2Schema "$I2B2_DB_NAME" i2b2pm
initI2b2Schema "$I2B2_DB_NAME" i2b2hive

# load data
loadI2b2Data "$I2B2_DB_NAME" false false
