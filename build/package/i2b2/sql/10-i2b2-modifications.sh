#!/bin/bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
# update structure of default i2b2 DB

psql $PSQL_PARAMS -d "$I2B2_DB_NAME" <<-EOSQL

    -- increase size of modifier_path in the modifier_dimension table
    ALTER TABLE i2b2demodata.modifier_dimension ALTER COLUMN modifier_path TYPE varchar(2000);

    -- increase size of concept_path in the concept_dimension table
    ALTER TABLE i2b2demodata.concept_dimension ALTER COLUMN concept_path TYPE varchar(2000);

    -- increase size of encounter_num values (too large for type INT)
    ALTER TABLE i2b2demodata.visit_dimension ALTER COLUMN encounter_num TYPE bigint;
    ALTER TABLE i2b2demodata.observation_fact ALTER COLUMN encounter_num TYPE bigint;
    ALTER TABLE i2b2demodata.encounter_mapping ALTER COLUMN encounter_num TYPE bigint;

    -- change tval_char to type text
    ALTER TABLE i2b2demodata.observation_fact ALTER COLUMN tval_char TYPE text;

EOSQL
