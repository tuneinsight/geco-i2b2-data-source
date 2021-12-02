#!/bin/bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

# hive configuration
psql $PSQL_PARAMS -d "$I2B2_DB_NAME" <<-EOSQL

    -- database lookups
    update i2b2hive.crc_db_lookup SET C_DOMAIN_ID = '$I2B2_DOMAIN_NAME' WHERE C_DOMAIN_ID = 'i2b2demo';
    UPDATE i2b2hive.im_db_lookup SET C_DOMAIN_ID = '$I2B2_DOMAIN_NAME' WHERE C_DOMAIN_ID = 'i2b2demo';
    UPDATE i2b2hive.ont_db_lookup SET C_DOMAIN_ID = '$I2B2_DOMAIN_NAME' WHERE C_DOMAIN_ID = 'i2b2demo';
    UPDATE i2b2hive.work_db_lookup SET C_DOMAIN_ID = '$I2B2_DOMAIN_NAME' WHERE C_DOMAIN_ID = 'i2b2demo';

    -- CRC cell parameters
    UPDATE i2b2hive.hive_cell_params
      SET value='-1'
      WHERE param_name_cd='edu.harvard.i2b2.crc.lockout.setfinderquery.count';
    UPDATE i2b2hive.hive_cell_params
      SET value='$I2B2_SERVICE_PASSWORD'
      WHERE param_name_cd='edu.harvard.i2b2.crc.pm.serviceaccount.password';

EOSQL

# PM configuration
I2B2_SERVICE_PASSWORD_HASH=$(java -classpath "$I2B2_PASSWORD_HASH_TOOL" I2b2PasswordHash "$I2B2_SERVICE_PASSWORD")
DEFAULT_USER_PASSWORD_HASH=$(java -classpath "$I2B2_PASSWORD_HASH_TOOL" I2b2PasswordHash "$DEFAULT_USER_PASSWORD")

psql $PSQL_PARAMS -d "$I2B2_DB_NAME" <<-EOSQL

    -- cell parameters
    insert into i2b2pm.pm_cell_params (datatype_cd, cell_id, project_path, param_name_cd, value, changeby_char, status_cd) values
        ('T', 'FRC', '/', 'DestDir', '$I2B2_FR_FILES_DIR', 'i2b2', 'A');

    -- hive & users data
    UPDATE i2b2pm.pm_hive_data SET DOMAIN_ID = '$I2B2_DOMAIN_NAME', DOMAIN_NAME = '$I2B2_DOMAIN_NAME' WHERE DOMAIN_ID = 'i2b2';

    UPDATE i2b2pm.PM_CELL_DATA SET URL = '$I2B2_URL/QueryToolService/' WHERE CELL_ID = 'CRC';
    UPDATE i2b2pm.PM_CELL_DATA SET URL = '$I2B2_URL/FRService/' WHERE CELL_ID = 'FRC';
    UPDATE i2b2pm.PM_CELL_DATA SET URL = '$I2B2_URL/OntologyService/' WHERE CELL_ID = 'ONT';
    UPDATE i2b2pm.PM_CELL_DATA SET URL = '$I2B2_URL/WorkplaceService/' WHERE CELL_ID = 'WORK';
    UPDATE i2b2pm.PM_CELL_DATA SET URL = '$I2B2_URL/IMService/' WHERE CELL_ID = 'IM';

    UPDATE i2b2pm.PM_USER_DATA SET PASSWORD = '$DEFAULT_USER_PASSWORD_HASH' WHERE USER_ID = 'i2b2';
    UPDATE i2b2pm.PM_USER_DATA SET PASSWORD = '$DEFAULT_USER_PASSWORD_HASH' WHERE USER_ID = 'demo';
    UPDATE i2b2pm.PM_USER_DATA SET PASSWORD = '$I2B2_SERVICE_PASSWORD_HASH' WHERE USER_ID = 'AGG_SERVICE_ACCOUNT';
EOSQL
