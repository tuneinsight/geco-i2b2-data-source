#!/bin/bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
# set up common medco ontology

psql $PSQL_PARAMS -d "$I2B2_DB_NAME" <<-EOSQL

    -- increase size of encounter_num values (too large for type INT)
    ALTER TABLE i2b2demodata.visit_dimension ALTER COLUMN encounter_num TYPE bigint;
    ALTER TABLE i2b2demodata.observation_fact ALTER COLUMN encounter_num TYPE bigint;
    ALTER TABLE i2b2demodata.encounter_mapping ALTER COLUMN encounter_num TYPE bigint;

    -- change tval_char to type text
    ALTER TABLE i2b2demodata.observation_fact ALTER COLUMN tval_char TYPE text;

EOSQL
