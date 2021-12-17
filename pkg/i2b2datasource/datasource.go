package i2b2datasource

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2api"
	i2b2apimodels "github.com/ldsec/geco-i2b2-data-source/pkg/i2b2api/models"
	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2datasource/models"
	gecosdk "github.com/ldsec/geco/pkg/sdk"
	"github.com/sirupsen/logrus"
)

// compile-time check that I2b2DataSource implements the interface sdk.DataSourcePlugin
var _ gecosdk.DataSourcePlugin = (*I2b2DataSource)(nil)

// Names of result data objects.
const (
	resultNameExploreQueryCount       string = "count"
	resultNameExploreQueryPatientList string = "patientList"
)

// NewI2b2DataSource creates an i2b2 data source.
// Implements sdk.DataSourcePluginFactory.
func NewI2b2DataSource(logger logrus.FieldLogger, config map[string]string) (plugin gecosdk.DataSourcePlugin, err error) {
	ds := new(I2b2DataSource)
	ds.logger = logger

	// todo: config keys
	// i2b2.api.username
	// i2b2.db.xxx
	// datasource.db.xxx

	// parse i2b2 API connection info and initialize i2b2 client
	ci := i2b2apimodels.ConnectionInfo{
		HiveURL:  config["i2b2.api.url"],
		Domain:   config["i2b2.api.domain"],
		Username: config["i2b2.api.username"],
		Password: config["i2b2.api.password"],
		Project:  config["i2b2.api.project"],
	}

	if ci.WaitTime, err = time.ParseDuration(config["i2b2.api.wait-time"]); err != nil {
		err = fmt.Errorf("parsing i2b2 wait time: %v", err)
		logger.Error(err)
		return nil, err
	}

	ds.i2b2Client = i2b2api.Client{
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

	// i2b2Client is the i2b2 client
	i2b2Client i2b2api.Client

	// i2b2OntMaxElements is the configuration for the maximum number of ontology elements to return from i2b2
	i2b2OntMaxElements string
}

// Query implements the data source interface Query function.
func (ds I2b2DataSource) Query(userID string, operation string, jsonParameters []byte) (jsonResults []byte, resultDataObjects map[string]gecosdk.DataObject, err error) {
	ds.logger.Infof("executing operation %v for user %v", operation, userID)
	ds.logger.Debugf("parameters: %v", string(jsonParameters))

	switch Operation(operation) {
	case OperationSearchConcept:
		decodedParams := &models.SearchConceptParameters{}
		if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
			return nil, nil, ds.logError("decoding parameters", err)
		} else if searchResults, err := ds.SearchConcept(decodedParams); err != nil {
			return nil, nil, ds.logError("executing query", err)
		} else if jsonResults, err = json.Marshal(searchResults); err != nil {
			return nil, nil, ds.logError("encoding results", err)
		}

	case OperationSearchModifier:
		decodedParams := &models.SearchModifierParameters{}
		if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
			return nil, nil, ds.logError("decoding parameters", err)
		} else if searchResults, err := ds.SearchModifier(decodedParams); err != nil {
			return nil, nil, ds.logError("executing query", err)
		} else if jsonResults, err = json.Marshal(searchResults); err != nil {
			return nil, nil, ds.logError("encoding results", err)
		}

	case OperationExploreQuery:
		var count int64
		var patientList []int64
		decodedParams := &models.ExploreQueryParameters{}
		if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
			return nil, nil, ds.logError("decoding parameters", err)
		} else if count, patientList, err = ds.ExploreQuery(decodedParams); err != nil {
			return nil, nil, ds.logError("executing query", err)
		}

		resultDataObjects = make(map[string]gecosdk.DataObject, 2)
		resultDataObjects[resultNameExploreQueryCount] = gecosdk.DataObject{IntValue: &count}
		resultDataObjects[resultNameExploreQueryPatientList] = gecosdk.DataObject{IntVector: patientList}

	default:
		return nil, nil, ds.logError(fmt.Sprintf("unknown query requested (%v)", operation), nil)
	}
	return
}

// logError creates and logs an error.
// todo: exists in GeCo, can be exposed by SDK code
func (ds I2b2DataSource) logError(errMsg string, causedBy error) (err error) {
	if causedBy == nil {
		err = fmt.Errorf("%v", errMsg)
	} else {
		err = fmt.Errorf("%v: %v", errMsg, causedBy)
	}
	ds.logger.Error(err)
	return err
}
