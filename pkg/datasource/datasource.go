package datasource

import (
	"fmt"
	"time"

	"github.com/ldsec/geco-i2b2-data-source/pkg/datasource/database"
	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2client"
	i2b2clientmodels "github.com/ldsec/geco-i2b2-data-source/pkg/i2b2client/models"
	gecomodels "github.com/ldsec/geco/pkg/models"
	gecosdk "github.com/ldsec/geco/pkg/sdk"
	"github.com/sirupsen/logrus"
)

// compile-time check that I2b2DataSource implements the interface sdk.DataSourcePlugin
var _ gecosdk.DataSourcePlugin = (*I2b2DataSource)(nil)

// Names of output data objects.
const (
	outputNameExploreQueryCount       gecosdk.OutputDataObjectName = "count"
	outputNameExploreQueryPatientList gecosdk.OutputDataObjectName = "patientList"
)

// NewI2b2DataSource creates an i2b2 data source. Implements sdk.DataSourcePluginFactory.
// Configuration keys:
// - I2b2: i2b2.api.url, i2b2.api.domain, i2b2.api.username, i2b2.api.password, i2b2.api.project, i2b2.api.wait-time, i2b2.api.ont-max-elements
// - Database: db.host, db.port, db.db-name, db.schema-name, db.user, db.password
func NewI2b2DataSource(logger logrus.FieldLogger, config map[string]string) (plugin gecosdk.DataSourcePlugin, err error) {
	ds := new(I2b2DataSource)
	ds.logger = logger

	// initialize database connection
	ds.db, err = database.NewPostgresDatabase(logger, config["db.host"], config["db.port"],
		config["db.db-name"], config["db.schema-name"], config["db.user"], config["db.password"])
	if err != nil {
		return nil, ds.logError("initializing database connection", err)
	}

	// parse i2b2 API connection info and initialize i2b2 client
	ci := i2b2clientmodels.ConnectionInfo{
		HiveURL:  config["i2b2.api.url"],
		Domain:   config["i2b2.api.domain"],
		Username: config["i2b2.api.username"],
		Password: config["i2b2.api.password"],
		Project:  config["i2b2.api.project"],
	}

	if ci.WaitTime, err = time.ParseDuration(config["i2b2.api.wait-time"]); err != nil {
		return nil, ds.logError("parsing i2b2 wait time", err)
	}

	ds.i2b2Client = i2b2client.Client{
		Logger: logger,
		Ci:     ci,
	}
	ds.i2b2OntMaxElements = config["i2b2.api.ont-max-elements"]

	ds.logger.Infof("initialized i2b2 data source for %v", ci.HiveURL)
	return ds, nil
}

// I2b2DataSource is an i2b2 data source for GeCo. It implements the data source interface.
type I2b2DataSource struct {

	// logger is the logger from GeCo
	logger logrus.FieldLogger

	// db is the database handler of the data source
	db *database.PostgresDatabase

	// i2b2Client is the i2b2 client
	i2b2Client i2b2client.Client

	// i2b2OntMaxElements is the configuration for the maximum number of ontology elements to return from i2b2
	i2b2OntMaxElements string
}

// Query implements the data source interface Query function.
func (ds I2b2DataSource) Query(userID string, operation string, jsonParameters []byte, outputDataObjectsSharedIDs map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID) (jsonResults []byte, outputDataObjects []gecosdk.DataObject, err error) {
	ds.logger.Infof("executing operation %v for user %v", operation, userID)
	ds.logger.Debugf("parameters: %v", string(jsonParameters))

	var handler OperationHandler
	switch Operation(operation) {
	case OperationSearchConcept:
		handler = ds.SearchConceptHandler
	case OperationSearchModifier:
		handler = ds.SearchModifierHandler
	case OperationExploreQuery:
		handler = ds.ExploreQueryHandler
	case OperationGetCohorts:
		handler = ds.GetCohortsHandler
	case OperationAddCohort:
		handler = ds.AddCohortHandler
	case OperationDeleteCohort:
		handler = ds.DeleteCohortHandler
	case OperationSurvivalQuery:
		return nil, nil, ds.logError("operation survivalQuery not implemented", nil) // todo
	case OperationSearchOntology:
		return nil, nil, ds.logError("operation searchOntology not implemented", nil) // todo

	default:
		return nil, nil, ds.logError(fmt.Sprintf("unknown query requested (%v)", operation), nil)
	}

	if jsonResults, outputDataObjects, err = handler(userID, jsonParameters, outputDataObjectsSharedIDs); err != nil {
		return nil, nil, ds.logError(fmt.Sprintf("executing operation %v", operation), err)
	}

	ds.logger.Infof("successfully executed operation %v for user %v", operation, userID)
	ds.logger.Debugf("results: %v", string(jsonResults))
	return
}

// logError creates and logs an error.
func (ds I2b2DataSource) logError(errMsg string, causedBy error) (err error) {
	if causedBy == nil {
		err = fmt.Errorf("%v", errMsg)
	} else {
		err = fmt.Errorf("%v: %v", errMsg, causedBy)
	}
	ds.logger.Error(err)
	return err
}
