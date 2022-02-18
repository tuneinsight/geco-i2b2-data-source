# SQL scripts
The `docker-entrypoint.sh` startup script of the Docker image will run the scripts contained in this folder before
starting i2b2, in order to do the initial loading of the i2b2 data in the postgresql database.
This loading is performed only if the i2b2 database does not exist already, i.e. if the data was not previously loaded.
The scripts are executed in alphanumerical order, so a numbering in the filename should be used.

The scripts must have the file extension `.sh` and handle failures correctly, e.g. by using `set -Eeuo pipefail`.

## `common.sh`
This script provides to other scripts common functions, it is meant to be sourced with `source "$(dirname "$0")/common.sh"`.
It contains the function that initialises an i2b2 schema.

## `05-i2b2-orig-data.sh`
This script loads the i2b2 untouched original data in the database as instructed in the i2b2 documentation.
Note that only the structure is loaded, i.e. the demo data is not loaded in order to save time.

## `10-i2b2-modifications.sh`
This scripts does modifications to the i2b2 original data structure loaded in the database, it should be used in order
to persist some modifications of the i2b2 database structure when it is needed.
Currently, it increases the size of some fields and modify the type of some other fields.

## `20-i2b2-configuration.sh`
This script configures i2b2 through the database.
For the hive configuration it adds the database lookups and sets some parameters of the CRC cell.
For the PM configuration it sets some parameters of the cell (notably the directory of the file repository),
sets the information about the project, and sets the passwords of the i2b2 users.

## `50-stored-procedures.sh`
This scripts loads the stored procedures located in `50-stored-procedures/`.
The procedures must have the file extension `.plpgql` and contain SQL code loaded the procedure.

### `50-stored-procedures/get_concept_codes.plpgsql`
A PL/pgSQL function that returns the concept codes for a given concept path and its descendants.

### `50-stored-procedures/get_modifier_codes.plpgsql`
A PL/pgSQL function that returns the modifier codes for a given modifier path and its descendants, for a given applied
path.

### `50-stored-procedures/get_ontology_elements.plpgsql`
A PL/pgSQL function that returns a set number of ontology elements whose paths contain the given search_string.

### `50-stored-procedures/table_name.plpgsql`
A PL/pgSQL function that returns the table name for a given table code.

## `90-test-data.sh`
This scripts loads a set of test data that is expected to exist after the data loaded and that is used for example for
unit or integration tests.