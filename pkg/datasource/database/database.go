package database

import (
	"database/sql"
	"database/sql/driver"
	"fmt"

	// Registering postgres driver
	"github.com/lib/pq"
	"github.com/sirupsen/logrus"
)

// NewPostgresDatabase initializes a connection to a postgres database, and loads its structure if not present.
func NewPostgresDatabase(logger logrus.FieldLogger, config PostgresDatabaseConfig, dbHandle *sql.DB) (db *PostgresDatabase, err error) {
	db = &PostgresDatabase{
		logger: logger,
		handle: dbHandle,
	}
	db.PostgresDatabaseConfig = config

	return db, db.loadDdl(db.Schema, db.User)
}

// PostgresDatabase wraps the Postgres database of the data source.
type PostgresDatabase struct {
	PostgresDatabaseConfig
	logger logrus.FieldLogger

	handle *sql.DB
}

// PostgresDatabaseConfig is the config used to connect to the postgres database
type PostgresDatabaseConfig struct {
	Host     string
	Port     string
	Database string
	Schema   string
	User     string
	Password string
}

// DriverName returns "postgres"
func (conf PostgresDatabaseConfig) DriverName() string {
	return "postgres"
}

// DataSourceName should return the connection string to the db: postgres example "host=localhost port=5432 user=test password=test dbname=test sslmode=disable"
func (conf PostgresDatabaseConfig) DataSourceName() string {
	return fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s search_path=%s sslmode=disable", conf.Host, conf.Port, conf.User, conf.Password, conf.Database, conf.Schema)
}

// Driver Should return the database driver
func (conf PostgresDatabaseConfig) Driver() driver.Driver {
	return &pq.Driver{}
}

// Name should return the name of the connected database
func (conf PostgresDatabaseConfig) Name() string {
	return conf.Database
}

func closeRows(rows *sql.Rows, logger logrus.FieldLogger) {
	if rows.Next() {
		logger.Warnf("leftover rows available")
	}

	if err := rows.Close(); err != nil {
		logger.Errorf("closing result rows: %v", err)
	}
}
