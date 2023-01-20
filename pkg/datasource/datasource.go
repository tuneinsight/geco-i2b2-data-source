package datasource

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/database"
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/i2b2client"
	i2b2clientmodels "github.com/tuneinsight/geco-i2b2-data-source/pkg/i2b2client/models"
	sdkmodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk/telemetry"
)

// compile-time check that I2b2DataSource implements the interface sdk.DataSource.
var _ sdk.DataSource = (*I2b2DataSource)(nil)

const (
	// DataSourceType is the type of the data source.
	DataSourceType sdk.DataSourceType = "i2b2"

	// DBCredentialsID is the ID for the database credentials.
	DBCredentialsID string = "dbCredentials"
	// I2B2CredentialsID is the ID for the i2b2 credentials.
	I2B2CredentialsID string = "i2b2Credentials"

	i2b2ConfigID   string = "i2b2Config"
	i2b2DBConfigID string = "i2b2DBConfig"
)

// NewI2b2DataSource creates an i2b2 data source. It implements sdk.DataSourceFactory.
func NewI2b2DataSource(dsc *sdk.DataSourceCore, config map[string]interface{}, manager *sdk.DBManager) (plugin sdk.DataSource, err error) {
	ds := new(I2b2DataSource)
	ds.DataSourceCore = *dsc
	ds.manager = manager
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

// SetContext sets a context of the data source
func (ds *I2b2DataSource) SetContext(ctx *context.Context) {
	ds.Ctx = ctx
}

// GetContext return of context of the data source
func (ds *I2b2DataSource) GetContext() *context.Context {
	return ds.Ctx
}

// MarshalBinary marshals the i2b2 config.
func (i2b2 *i2b2Config) MarshalBinary() (data []byte, err error) {
	return json.Marshal(i2b2)
}

// UnmarshalBinary unmarshals the i2b2 config.
func (i2b2 *i2b2Config) UnmarshalBinary(data []byte) (err error) {
	return json.Unmarshal(data, i2b2)
}

// GetDataSourceConfig gets the data source config.
func (ds *I2b2DataSource) GetDataSourceConfig() map[string]interface{} {
	return map[string]interface{}{
		i2b2ConfigID:   ds.i2b2Config,
		i2b2DBConfigID: ds.dbConfig,
	}
}

// SetDataSourceConfig sets the data source config.
func (ds *I2b2DataSource) SetDataSourceConfig(config map[string]interface{}) error {
	if i2b2Conf, ok := config[i2b2ConfigID].(*i2b2Config); ok || config[i2b2ConfigID] == nil {
		ds.i2b2Config = i2b2Conf
	} else {
		return fmt.Errorf("config with key %s is not of the right type: expected %T, got %T", i2b2ConfigID, &i2b2Config{}, config[i2b2ConfigID])
	}
	return nil
}

// Data returns all the data to be stored in the TI Note object storage.
func (ds *I2b2DataSource) Data() map[string]interface{} {
	return sdk.DataImpl(ds)
}

// Config configures the datasource.
// Configuration keys:
// - I2b2: i2b2.api.url, i2b2.api.domain, i2b2.api.project, i2b2.api.wait-time, i2b2.api.ont-max-elements
// - Database: db.host, db.port, db.db-name, db.schema-name
func (ds *I2b2DataSource) Config(logger logrus.FieldLogger, config map[string]interface{}) (err error) {
	ds.logger = logger

	// retrieving data source credentials
	dbCred, err := ds.CredentialsProvider.GetCredentials(DBCredentialsID)
	if err != nil {
		return ds.logError("while retrieving db credentials", err)
	}
	i2b2Cred, err := ds.CredentialsProvider.GetCredentials(I2B2CredentialsID)
	if err != nil {
		return ds.logError("while retrieving i2b2 credentials", err)
	}

	// store db config
	ds.dbConfig.Host = (config["db.host"].(string))
	ds.dbConfig.Port = config["db.port"].(string)
	ds.dbConfig.Database = config["db.db-name"].(string)
	ds.dbConfig.Schema = config["db.schema-name"].(string)
	ds.dbConfig.User = dbCred.Username()
	ds.dbConfig.Password = dbCred.Password()

	// store i2b2 config
	ds.i2b2Config.URL = config["i2b2.api.url"].(string)
	ds.i2b2Config.Domain = config["i2b2.api.domain"].(string)
	ds.i2b2Config.Username = i2b2Cred.Username()
	ds.i2b2Config.Password = i2b2Cred.Password()
	ds.i2b2Config.Project = config["i2b2.api.project"].(string)
	ds.i2b2Config.OntMaxElements = config["i2b2.api.ont-max-elements"].(string)
	if ds.i2b2Config.WaitTime, err = time.ParseDuration(config["i2b2.api.wait-time"].(string)); err != nil {
		return ds.logError("parsing i2b2 wait time", err)
	}
	if ds.manager == nil {
		return ds.logError("manager should be set", nil)
	}
	db, err := ds.manager.GetDatabase(ds.dbConfig)
	if err != nil {
		return ds.logError("retrieving database", err)
	}
	// initialize database connection
	ds.db, err = database.NewPostgresDatabase(ds.Ctx, ds.logger, *ds.dbConfig, db.DB)
	if err != nil {
		return ds.logError("initializing database connection", err)
	}

	newCtx := context.Background()
	if ds.Ctx != nil {
		newCtx = telemetry.CarryTelemetryContext(*ds.Ctx)
	}

	// initialize i2b2 client
	ds.i2b2Client = i2b2client.Client{
		Ctx:    newCtx,
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
	ds.db, err = database.NewPostgresDatabase(ds.Ctx, ds.logger, *ds.dbConfig, db.DB)
	if err != nil {
		return ds.logError("initializing database connection", err)
	}

	newCtx := *ds.Ctx
	// initialize i2b2 client
	ds.i2b2Client = i2b2client.Client{
		Ctx:    newCtx,
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

// GetDataSourceCustomData returns a map of the data values stored along this data source
func (ds *I2b2DataSource) GetDataSourceCustomData() map[string]interface{} {
	return map[string]interface{}{
		"dbConfig":   ds.dbConfig,
		"i2b2Config": ds.i2b2Config,
	}
}

// Query implements the data source interface Query function.
func (ds *I2b2DataSource) Query(userID string, params map[string]interface{}, resultKeys ...string) (map[string]interface{}, error) {
	operation, ok := params["operation"].(string)
	if !ok {
		return nil, fmt.Errorf("operation not specified")
	}

	jsonParams, ok := params["params"].([]byte)
	if !ok {
		return nil, fmt.Errorf("params not specified")
	}

	if len(resultKeys) == 0 {
		resultKeys = append(resultKeys, sdk.DefaultResultKey)
	}

	// Get outputDataObjectsSharedIDs from the jsonParams
	var unmarshaledJSON map[string]interface{}
	if err := json.Unmarshal(jsonParams, &unmarshaledJSON); err != nil {
		return nil, err
	}
	outputDataObjectsSharedIDs := params["outputDataObjectsSharedIDs"].(map[sdk.OutputDataObjectName]sdkmodels.DataObjectSharedID)
	if unmarshaledJSON["outputDataObjectsSharedIDs"] != nil {

		for k, v := range unmarshaledJSON["outputDataObjectsSharedIDs"].(map[string]interface{}) {
			outputDataObjectsSharedIDs[sdk.OutputDataObjectName(k)] = sdkmodels.DataObjectSharedID(v.(string))
		}
	}

	span := telemetry.StartSpan(ds.Ctx, "datasource:i2b2", "Query:"+operation)
	defer span.End()

	ds.logger.Infof("executing operation %v for user %v", operation, userID)
	ds.logger.Debugf("parameters: %v", string(jsonParams))

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
		return nil, ds.logError(fmt.Sprintf("unknown query requested (%v)", operation), nil)
	}

	jsonResults, outputDataObjects, err := handler(userID, jsonParams, outputDataObjectsSharedIDs)
	if err != nil {
		return nil, ds.logError(fmt.Sprintf("executing operation %v", operation), err)
	}

	ds.logger.Infof("successfully executed operation %v for user %v", operation, userID)

	results := make(map[string]interface{})
	results[sdk.DefaultResultKey] = jsonResults
	results["outputDataObjects"] = outputDataObjects
	return results, nil
}

// logError creates and logs an error.
func (ds *I2b2DataSource) logError(errMsg string, causedBy error) (err error) {
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
