package database

import (
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
)

const unitTestsSchemaName = "gecodatasourceunittest"
const testDataStatement = `
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
		('cohort1', NOW(), '11111111-1111-1111-1111-111111111111');
	INSERT INTO saved_cohort(name, create_date, explore_query_id) VALUES
		('cohort3', NOW(), '33333333-3333-3333-3333-333333333333');
	INSERT INTO saved_cohort(name, create_date, explore_query_id) VALUES
		('cohort4', NOW(), '44444444-4444-4444-4444-444444444444');
COMMIT;
`

func getDB(t *testing.T) *PostgresDatabase {
	db, err := NewPostgresDatabase(logrus.StandardLogger(),
		"localhost", "5432", "i2b2", unitTestsSchemaName, "postgres", "postgres")
	require.NoError(t, err)

	return db
}

func dbLoadTestData(t *testing.T, db *PostgresDatabase) {
	_, err := db.handle.Exec(testDataStatement)
	require.NoError(t, err)
}

func dbCleanup(t *testing.T, db *PostgresDatabase) {
	_, err := db.handle.Exec("DROP SCHEMA " + unitTestsSchemaName + " CASCADE;")
	require.NoError(t, err)
}

func TestDDL(t *testing.T) {
	db := getDB(t)
	dbLoadTestData(t, db)
	dbCleanup(t, db)
}
