package datasource

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/database"
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/i2b2client"
	i2b2clientmodels "github.com/tuneinsight/geco-i2b2-data-source/pkg/i2b2client/models"
	sdkmodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk"
)

// compile-time check that I2b2DataSource implements the interface sdk.DataSource.
var _ sdk.DataSource = (*I2b2DataSource)(nil)

// DataSourceType is the type of the data source.
var DataSourceType sdk.DataSourceType = "i2b2-geco"

// NewI2b2DataSource creates an i2b2 data source. Implements sdk.DataSourceFactory.
func NewI2b2DataSource(id sdkmodels.DataSourceID, owner, name string, manager *sdk.DBManager) (plugin sdk.DataSource, err error) {
	ds := new(I2b2DataSource)
	ds.manager = manager
	ds.DataSourceDatabaseModel = sdk.NewDataSourceDatabaseModel(id, owner, name, DataSourceType)
	ds.dbConfig = new(database.PostgresDatabaseConfig)
	ds.i2b2Config = new(i2b2Config)

	return ds, nil
}

// I2b2DataSource is an i2b2 data source for the TI Note. It implements the data source interface.
type I2b2DataSource struct {
	sdk.DataSourceCore

	// logger is the logger of the TI Note
	logger logrus.FieldLogger

	// manager is the connection manager used to get the database connection
	manager *sdk.DBManager
	// db is the database handler of the data source
	db *database.PostgresDatabase

	// i2b2Client is the i2b2 client
	i2b2Client i2b2client.Client

	// dbConfig contains the DB configuration
	dbConfig *database.PostgresDatabaseConfig

	// i2b2Config contains the i2b2 configuration
	i2b2Config *i2b2Config
}

type i2b2Config struct {
	// URL contains the i2b2 hive url.
	URL string
	// Domain contains the i2b2 login domain.
	Domain string
	// Username contains the i2b2 login username.
	Username string
	// Password contains the i2b2 login password.
	Password string //TODO: is it safe?
	// Project contains the i2b2 project ID.
	Project string
	// WaitTime contains the maximum amount of time in milliseconds to wait for i2b2 to provide a synchronous result.
	WaitTime time.Duration
	// OntMaxElements contains the maximum number of ontology elements returned by a request.
	OntMaxElements string
}

// MarshalBinary marshals the i2b2 config.
func (i2b2 *i2b2Config) MarshalBinary() (data []byte, err error) {
	return json.Marshal(i2b2)
}

// UnmarshalBinary unmarshals the i2b2 config.
func (i2b2 *i2b2Config) UnmarshalBinary(data []byte) (err error) {
	return json.Unmarshal(data, i2b2)
}

// FromModel sets the fields of the local data source given a model.
func (ds *I2b2DataSource) FromModel(model *sdk.DataSourceDatabaseModel) {
	ds.DataSourceDatabaseModel = model
}

// Config configures the datasource.
// Configuration keys:
// - I2b2: i2b2.api.url, i2b2.api.domain, i2b2.api.username, i2b2.api.password, i2b2.api.project, i2b2.api.wait-time, i2b2.api.ont-max-elements
// - Database: db.host, db.port, db.db-name, db.schema-name, db.user, db.password
func (ds *I2b2DataSource) Config(logger logrus.FieldLogger, config map[string]interface{}) (err error) {
	ds.logger = logger

	// store db config
	ds.dbConfig.Host = (config["db.host"].(string))
	ds.dbConfig.Port = config["db.port"].(string)
	ds.dbConfig.Database = config["db.db-name"].(string)
	ds.dbConfig.Schema = config["db.schema-name"].(string)
	ds.dbConfig.User = config["db.user"].(string)
	ds.dbConfig.Password = config["db.password"].(string)

	// store i2b2 config
	ds.i2b2Config.URL = config["i2b2.api.url"].(string)
	ds.i2b2Config.Domain = config["i2b2.api.domain"].(string)
	ds.i2b2Config.Username = config["i2b2.api.username"].(string)
	ds.i2b2Config.Password = config["i2b2.api.password"].(string)
	ds.i2b2Config.Project = config["i2b2.api.project"].(string)
	ds.i2b2Config.OntMaxElements = config["i2b2.api.ont-max-elements"].(string)
	if ds.i2b2Config.WaitTime, err = time.ParseDuration(config["i2b2.api.wait-time"].(string)); err != nil {
		return ds.logError("parsing i2b2 wait time", err)
	}
	if ds.manager == nil {
		return fmt.Errorf("manager should be set")
	}
	db, err := ds.manager.GetDatabase(ds.dbConfig)
	if err != nil {
		return ds.logError("retrieving database", err)
	}
	// initialize database connection
	ds.db, err = database.NewPostgresDatabase(ds.logger, *ds.dbConfig, db.DB)
	if err != nil {
		return ds.logError("initializing database connection", err)
	}

	// initialize i2b2 client
	ds.i2b2Client = i2b2client.Client{
		Logger: ds.logger,
		Ci: i2b2clientmodels.ConnectionInfo{
			HiveURL:  ds.i2b2Config.URL,
			Domain:   ds.i2b2Config.Domain,
			Username: ds.i2b2Config.Username,
			Password: ds.i2b2Config.Password,
			Project:  ds.i2b2Config.Project,
			WaitTime: ds.i2b2Config.WaitTime,
		},
	}

	ds.logger.Infof("initialized i2b2 data source for %v", ds.i2b2Config.URL)

	return
}

// ConfigFromDB configures the data source retrieved from the DB.
func (ds *I2b2DataSource) ConfigFromDB(logger logrus.FieldLogger) (err error) {
	ds.logger = logger

	// initialize database connection
	if ds.manager == nil {
		return fmt.Errorf("db manager should be set")
	}
	db, err := ds.manager.GetDatabase(ds.dbConfig)
	if err != nil {
		return ds.logError("retrieving database", err)
	}
	// initialize database connection
	ds.db, err = database.NewPostgresDatabase(ds.logger, *ds.dbConfig, db.DB)
	if err != nil {
		return ds.logError("initializing database connection", err)
	}

	// initialize i2b2 client
	ds.i2b2Client = i2b2client.Client{
		Logger: ds.logger,
		Ci: i2b2clientmodels.ConnectionInfo{
			HiveURL:  ds.i2b2Config.URL,
			Domain:   ds.i2b2Config.Domain,
			Username: ds.i2b2Config.Username,
			Password: ds.i2b2Config.Password,
			Project:  ds.i2b2Config.Project,
			WaitTime: ds.i2b2Config.WaitTime,
		},
	}

	ds.logger.Infof("initialized i2b2 data source for %v", ds.i2b2Config.URL)

	return
}

// GetData returns the csv data stored in the data source.
func (ds *I2b2DataSource) GetData(query string) ([]string, [][]float64) {
	return nil, nil
}

// LoadData loads a csv into the local data source, saving it in the datamanager and updating the data source.
func (ds *I2b2DataSource) LoadData(_ []string, _ interface{}) error {
	return nil
}

// Data returns a map of the data values stored along this data source
func (ds *I2b2DataSource) Data() map[string]interface{} {
	return map[string]interface{}{
		"dbConfig":   ds.dbConfig,
		"i2b2Config": ds.i2b2Config,
	}
}

// Query implements the data source interface Query function.
func (ds *I2b2DataSource) Query(userID string, operation string, jsonParameters []byte, outputDataObjectsSharedIDs map[sdk.OutputDataObjectName]sdkmodels.DataObjectSharedID) (jsonResults []byte, outputDataObjects []sdk.DataObject, err error) {
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
		handler = ds.SurvivalQueryHandler
	case OperationSearchOntology:
		handler = ds.SearchOntologyHandler
	case OperationStatisticsQuery:
		handler = ds.StatisticsQueryHandler

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

// Close closes the i2b2 datasource
func (ds *I2b2DataSource) Close() (err error) {
	if ds.manager == nil {
		return fmt.Errorf("manager should be set before closing datasource")
	}
	return ds.manager.Close(ds.dbConfig)
}
