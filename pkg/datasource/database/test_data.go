package database

import (
	"fmt"
)

// TestSchemaName defines the database schema name used for tests.
const TestSchemaName = "gecodatasourcetest"
const loadTestDataStatement = `
BEGIN;
	INSERT INTO explore_query(id, create_date, user_id, status, definition, result_i2b2_patient_set_id,
		result_geco_shared_id_count, result_geco_shared_id_patient_list) VALUES
		('00000000-0000-0000-0000-000000000000', NOW(), 'testuser1', 'success', '{"query": {}}',
		 0, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002');
	INSERT INTO explore_query(id, create_date, user_id, status, definition, result_i2b2_patient_set_id,
		result_geco_shared_id_count, result_geco_shared_id_patient_list) VALUES
		('11111111-1111-1111-1111-111111111111', NOW(), 'testuser1', 'success', '{"query": {}}',
		 1, '11111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111113');
	INSERT INTO explore_query(id, create_date, user_id, status, definition, result_i2b2_patient_set_id,
		result_geco_shared_id_count, result_geco_shared_id_patient_list) VALUES
		('22222222-2222-2222-2222-222222222222', NOW(), 'testuser1', 'error', '{"query": {}}',
		 NULL, NULL, NULL);
	INSERT INTO explore_query(id, create_date, user_id, status, definition, result_i2b2_patient_set_id,
		result_geco_shared_id_count, result_geco_shared_id_patient_list) VALUES
		('33333333-3333-3333-3333-333333333333', NOW(), 'testuser2', 'success', '{"query": {}}',
		 2, '33333333-3333-3333-3333-333333333334', '33333333-3333-3333-3333-333333333335');
	INSERT INTO explore_query(id, create_date, user_id, status, definition, result_i2b2_patient_set_id,
		result_geco_shared_id_count, result_geco_shared_id_patient_list) VALUES
		('44444444-4444-4444-4444-444444444444', NOW(), 'testuser2', 'success', '{"query": {}}',
		 3, '44444444-4444-4444-4444-444444444445', '44444444-4444-4444-4444-444444444446');

	INSERT INTO saved_cohort(name, create_date, explore_query_id) VALUES
		('cohort1', '2021-12-20T13:47:24.015216Z', '11111111-1111-1111-1111-111111111111');
	INSERT INTO saved_cohort(name, create_date, explore_query_id) VALUES
		('cohort3', '2021-12-21T13:47:24.015216Z', '33333333-3333-3333-3333-333333333333');
	INSERT INTO saved_cohort(name, create_date, explore_query_id) VALUES
		('cohort4', '2021-12-22T13:47:24.015216Z', '44444444-4444-4444-4444-444444444444');
COMMIT;
`

// TestLoadData loads test data into the database. For usage with tests.
func (db PostgresDatabase) TestLoadData() error {
	db.logger.Warnf("loading test data")

	if _, err := db.handle.Exec(loadTestDataStatement); err != nil {
		return fmt.Errorf("executing loadTestDataStatement: %v", err)
	}
	return nil
}

// TestCleanUp deletes ALL test data and structure of the data source. Use with caution!
func (db PostgresDatabase) TestCleanUp() error {
	db.logger.Warnf("deleting all test data from the database schema")

	if _, err := db.handle.Exec(deleteSchemaStatement, TestSchemaName); err != nil {
		return fmt.Errorf("executing deleteSchemaStatement: %v", err)
	}
	return nil
}
