#!/usr/bin/env bash
set -Eeuo pipefail

# wait for postgres to be available
export PGPASSWORD="$I2B2_DB_PW"
export PSQL_PARAMS="-v ON_ERROR_STOP=1 -h ${I2B2_DB_HOST} -p ${I2B2_DB_PORT} -U ${I2B2_DB_USER}"
until psql $PSQL_PARAMS -d postgres -c '\q'; do
  >&2 echo "Waiting for postgresql..."
  sleep 1
done

# load initial data if database does not exist (credentials must be valid and have create database right)
DB_CHECK=$(psql ${PSQL_PARAMS} -d postgres -X -A -t -c "select count(*) from pg_database where datname = '${I2B2_DB_NAME}';")
if [[ "$DB_CHECK" -ne "1" ]]; then
  echo "Initialising i2b2 database"
  psql $PSQL_PARAMS -d postgres <<-EOSQL
      CREATE DATABASE ${I2B2_DB_NAME};
EOSQL

  # Create user and grant rights if they do not exist
  USER_CHECK=$(psql ${PSQL_PARAMS} -d postgres -X -A -t -c "SELECT count(*) FROM pg_user WHERE usename = '${I2B2_DB_USER}';")
  if [[ "$USER_CHECK" -ne "1" ]]; then
    echo "Create user ${I2B2_DB_USER} and grand rights"
    psql $PSQL_PARAMS -d postgres <<-EOSQL
        CREATE USER ${I2B2_DB_USER}  LOGIN PASSWORD '${I2B2_DB_PW}';
        GRANT ALL PRIVILEGES ON DATABASE ${I2B2_DB_NAME} TO ${I2B2_DB_USER};
EOSQL
  fi

  export I2B2_DATA_DIR=/tmp/i2b2-data
  mkdir -p "$I2B2_DATA_DIR"
  tar xvzf "$I2B2_DATA_ARCHIVE" -C "$I2B2_DATA_DIR"
  for f in "$I2B2_SQL_DIR"/*.sh; do
      bash "$f"
  done
  rm -rf "$I2B2_DATA_DIR"
fi

# execute pre-init scripts & run wildfly
for f in "$PRE_INIT_SCRIPT_DIR"/*.sh; do
    bash "$f"
done
exec /opt/jboss/wildfly/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0
