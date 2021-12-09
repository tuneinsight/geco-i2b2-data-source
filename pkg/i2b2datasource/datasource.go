package i2b2datasource

import (
	"fmt"
	"time"

	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2api"
	i2b2apimodels "github.com/ldsec/geco-i2b2-data-source/pkg/i2b2api/models"
	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2datasource/models"
	"github.com/ldsec/geco/pkg/datamanager"
	"github.com/mitchellh/mapstructure"
	"github.com/sirupsen/logrus"
)

// todo: linting, remove from models (both packages)

type queryType string
const (
	queryTypeSearchConcept  queryType = "searchConcept"
	queryTypeSearchModifier queryType = "searchModifier"
	queryTypeExploreQuery   queryType = "exploreQuery"
	queryTypeGetCohorts     queryType = "getCohorts"
	queryTypeAddCohort queryType = "addCohort"
	queryTypeDeleteCohort queryType = "deleteCohort"
	queryTypeSurvivalQuery queryType = "survivalQuery"
	queryTypeSearchOntology queryType = "searchOntology"
)

const (
	sharedIdExploreQueryCount string = "count"
	sharedIdExploreQueryPatientList string = "patientList"
)

type I2b2DataSource struct {

	// init is true if the I2b2DataSource has been initialized.
	init bool

	// dm is the GeCo data manager
	dm *datamanager.DataManager

	// logger is the logger from GeCo
	logger logrus.FieldLogger

	// i2b2Client is the i2b2 client
	i2b2Client i2b2api.Client

	// i2b2OntMaxElements is the configuration for the maximum number of ontology elements to return from i2b2
	i2b2OntMaxElements string
}


func (ds *I2b2DataSource) Init(dm *datamanager.DataManager, logger logrus.FieldLogger, config map[string]string) (err error) {
	fmt.Println("called init")

	ds.dm = dm
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
		return err
	}

	ds.i2b2Client = i2b2api.Client{
		Logger: logger,
		Ci:ci,
	}
	ds.i2b2OntMaxElements = config["i2b2.api.ont-max-elements"]

	ds.init = true
	ds.logger.Infof("initialized i2b2 data source for %v", ci.HiveURL)
	return nil
}

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

func (ds I2b2DataSource) Query(userID string, operation string, parameters map[string]interface{}, resultsSharedIds map[string]string) (results map[string]interface{}, err error) {
	if !ds.init {
		panic(fmt.Errorf("data source is not initialized"))
	}
	ds.logger.Infof("executing operation %v for user %v", operation, userID)
	ds.logger.Debugf("parameters: %+v", parameters)
	ds.logger.Debugf("resultsSharedIds: %+v", resultsSharedIds)

	// todo: decoder might need squash param set

	results = make(map[string]interface{})
	switch queryType(operation) {
	case queryTypeSearchConcept:
		decodedParams := &models.SearchConceptParameters{}
		if err := mapstructure.Decode(parameters, decodedParams); err != nil {
			return nil, ds.logError("decoding parameters", err)
		} else if searchResults, err := ds.SearchConcept(decodedParams); err != nil {
			return nil, ds.logError("executing query", err)
		} else if err := mapstructure.Decode(searchResults, &results); err != nil {
			return nil, ds.logError("encoding results", err)
		}

	case queryTypeSearchModifier:
		decodedParams := &models.SearchModifierParameters{}
		if err := mapstructure.Decode(parameters, decodedParams); err != nil {
			return nil, ds.logError("decoding parameters", err)
		} else if searchResults, err := ds.SearchModifier(decodedParams); err != nil {
			return nil, ds.logError("executing query", err)
		} else if err := mapstructure.Decode(searchResults, &results); err != nil {
			return nil, ds.logError("encoding results", err)
		}

	case queryTypeExploreQuery:
		countSharedID, countOK := resultsSharedIds[sharedIdExploreQueryCount]
		patientListSharedID, patientListOK := resultsSharedIds[sharedIdExploreQueryPatientList]
		if !countOK || !patientListOK {
			return nil, ds.logError("missing results shared ID", nil)
		}

		decodedParams := &models.ExploreQueryParameters{}
		if err := mapstructure.Decode(parameters, decodedParams); err != nil {
			return nil, ds.logError("decoding parameters", err)
		} else if count, patientList, err := ds.ExploreQuery(decodedParams); err != nil {
			return nil, ds.logError("executing query", err)
		} else if err := ds.storeIntValue(count, countSharedID); err != nil {
			return nil, ds.logError("storing count", err)
		} else if err := ds.storeIntVector(patientList, patientListSharedID); err != nil {
			return nil, ds.logError("storing patient list", err)
		}

	default:
		return nil, ds.logError(fmt.Sprintf("unknown query requested (%v)", operation), nil)
	}
	return
}
