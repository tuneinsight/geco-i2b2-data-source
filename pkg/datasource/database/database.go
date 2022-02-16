package database

import (
	"database/sql"
	"fmt"

	// Registering postgres driver
	_ "github.com/lib/pq"
	"github.com/sirupsen/logrus"
)

// NewPostgresDatabase initializes a connection to a postgres database, and loads its structure if not present.
func NewPostgresDatabase(logger logrus.FieldLogger, host, port, databaseName, schemaName, userLogin, userPassword string) (db *PostgresDatabase, err error) {
	connectionString := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s search_path=%s sslmode=disable", host, port, userLogin, userPassword, databaseName, schemaName)

	logger.Infof("initializing connection to postgres database %v", host)
	logger.Debugf("postgres connection string is %v", connectionString)

	dbHandle, err := sql.Open("postgres", connectionString)
	if err != nil {
		return nil, fmt.Errorf("initializing connection to postgres database: %v", err)
	}

	db = &PostgresDatabase{
		logger: logger,
		handle: dbHandle,
	}

	return db, db.loadDdl(schemaName, userLogin)
}

// PostgresDatabase wraps the Postgres database of the data source.
type PostgresDatabase struct {
	logger logrus.FieldLogger

	handle *sql.DB
}

func closeRows(rows *sql.Rows, logger logrus.FieldLogger) {
	if rows.Next() {
		logger.Warnf("leftover rows available")
	}

	if err := rows.Close(); err != nil {
		logger.Errorf("closing result rows: %v", err)
	}
}
