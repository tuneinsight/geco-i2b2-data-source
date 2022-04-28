#!/bin/bash
set -Eeuo pipefail

function createDBuser {
  DB_NAME=$1
  DB_USER=$2
  DB_PWD=$3

  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE "$DB_NAME";
    GRANT ALL PRIVILEGES ON DATABASE "$DB_NAME" TO "$DB_USER";
EOSQL
}

createDBuser $I2B2_DB_NAME $I2B2_DB_USER $I2B2_DB_PW