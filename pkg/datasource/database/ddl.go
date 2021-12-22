package database

import "fmt"

const ddlLoaded = `SELECT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = $1);`

const createDeleteSchemaFunctions = `
CREATE OR REPLACE FUNCTION public.create_gecoi2b2datasource_schema(schema_name NAME, user_name NAME)
RETURNS BOOL AS '
	BEGIN
		EXECUTE ''CREATE SCHEMA '' || schema_name;
		EXECUTE ''GRANT ALL ON SCHEMA '' || schema_name || '' TO '' || user_name;
		EXECUTE ''GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA '' || schema_name || '' TO '' || user_name;
		RETURN true;
	END;
' LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public.delete_gecoi2b2datasource_schema(schema_name NAME)
RETURNS BOOL AS '
	BEGIN
		EXECUTE ''DROP SCHEMA '' || schema_name || '' CASCADE'';
		RETURN true;
	END;
' LANGUAGE PLPGSQL;
`

const createSchemaStatement = `SELECT public.create_gecoi2b2datasource_schema($1::name, $2::name);`

const deleteSchemaStatement = `SELECT public.delete_gecoi2b2datasource_schema($1::name);`

const ddlStatement = `
BEGIN;
	CREATE TYPE query_status AS ENUM ('requested', 'running', 'success', 'error');

	CREATE TABLE IF NOT EXISTS explore_query(
		id uuid NOT NULL,
		create_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
		user_id character varying(255) NOT NULL,
		status query_status NOT NULL,
		definition TEXT NOT NULL,

		result_i2b2_patient_set_id integer,
		result_geco_shared_id_count uuid,
		result_geco_shared_id_patient_list uuid,
		
		PRIMARY KEY (id)
	);

	CREATE TABLE IF NOT EXISTS saved_cohort(
		name character varying(255) NOT NULL,
		create_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
		explore_query_id uuid NOT NULL,
	
		CONSTRAINT saved_cohort_pkey PRIMARY KEY (name, explore_query_id),
		CONSTRAINT saved_cohort_fkey_explore_query FOREIGN KEY (explore_query_id) REFERENCES explore_query(id)
	);
COMMIT;
`

// loadDdl loads the data structure of the database.
func (db PostgresDatabase) loadDdl(schemaName, userLogin string) (err error) {

	// check if DDL was loaded
	var isDdlLoaded bool
	if rows, err := db.handle.Query(ddlLoaded, schemaName); err != nil {
		return fmt.Errorf("querying ddlLoaded: %v", err)
	} else if !rows.Next() {
		return fmt.Errorf("no available rows in ddlLoaded: %v", err)
	} else if err = rows.Scan(&isDdlLoaded); err != nil {
		return fmt.Errorf("scanning rows of ddlLoaded: %v", err)
	} else {
		closeRows(rows, db.logger)
	}

	// load DDL if not already loaded
	if !isDdlLoaded {
		db.logger.Infof("database structure does not exist, loading DDL")
		if _, err = db.handle.Exec(createDeleteSchemaFunctions); err != nil {
			return fmt.Errorf("executing createDeleteSchemaFunctions: %v", err)
		}
		if _, err = db.handle.Exec(createSchemaStatement, schemaName, userLogin); err != nil {
			return fmt.Errorf("executing createSchemaStatement: %v", err)
		}
		if _, err = db.handle.Exec(ddlStatement); err != nil {
			return fmt.Errorf("executing ddlStatement: %v", err)
		}
	}
	return nil
}
