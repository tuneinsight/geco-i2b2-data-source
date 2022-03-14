package database

import (
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk"
)

var config = PostgresDatabaseConfig{
	Host:     "localhost",
	Port:     "5433",
	Database: "i2b2",
	Schema:   TestSchemaName,
	User:     "postgres",
	Password: "postgres",
}

func getDB(t *testing.T) *PostgresDatabase {
	log := logrus.StandardLogger()
	log.SetLevel(logrus.DebugLevel)

	manager := sdk.NewDBManager(sdk.DBManagerConfig{
		MaxConnectionAttempts:              3,
		SleepingTimeBetweenAttemptsSeconds: 2,
	})
	mDB, err := manager.NewDatabase(config)
	require.NoError(t, err)

	db, err := NewPostgresDatabase(log, config, mDB.DB)
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
