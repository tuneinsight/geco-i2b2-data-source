package database

import (
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
)

func getDB(t *testing.T) *PostgresDatabase {
	log := logrus.StandardLogger()
	log.SetLevel(logrus.DebugLevel)

	db, err := NewPostgresDatabase(log, "localhost", "5432", "i2b2", TestSchemaName, "postgres", "postgres")
	require.NoError(t, err)

	err = db.TestLoadData()
	require.NoError(t, err)

	return db
}

func dbCleanUp(t *testing.T, db *PostgresDatabase) {
	err := db.TestCleanUp()
	require.NoError(t, err)
}

func TestDDL(t *testing.T) {
	db := getDB(t)
	dbCleanUp(t, db)
}
