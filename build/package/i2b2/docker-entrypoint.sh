#!/usr/bin/env bash
set -Eeuo pipefail

# wait for postgres to be available
export PGPASSWORD="$I2B2_DB_PW"
export PSQL_PARAMS="-v -h ${I2B2_DB_HOST} -p ${I2B2_DB_PORT} -U ${I2B2_DB_USER}"
until psql $PSQL_PARAMS -d postgres -c '\q'; do
  >&2 echo "Waiting for postgresql..."
  sleep 2
done

echo "Stopped waiting... on database ${I2B2_DB_NAME}"

for f in "$I2B2_SQL_DIR"/*.sh; do
  bash "$f"
done

# execute pre-init scripts & run wildfly
for f in "$PRE_INIT_SCRIPT_DIR"/*.sh; do
    bash "$f"
done
exec /opt/jboss/wildfly/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0
