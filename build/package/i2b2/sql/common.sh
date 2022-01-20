#!/bin/bash
set -Eeuo pipefail

# i2b2 web service URL used in configuration
export I2B2_URL="http://i2b2:8080/i2b2/services"

function initI2b2Schema {
    DB_NAME="$1"
    SCHEMA_NAME="$2"
    psql $PSQL_PARAMS -d "$DB_NAME" <<-EOSQL
        create schema $SCHEMA_NAME;
        grant all on schema $SCHEMA_NAME to $I2B2_DB_USER;
        grant all privileges on all tables in schema $SCHEMA_NAME to $I2B2_DB_USER;
EOSQL
}
