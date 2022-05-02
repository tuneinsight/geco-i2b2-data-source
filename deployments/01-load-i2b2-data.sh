#!/bin/bash
set -Eeuo pipefail

PGPASSWORD=$I2B2_DB_PW psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$I2B2_DB_NAME" < /02-i2b2-test-data.sql