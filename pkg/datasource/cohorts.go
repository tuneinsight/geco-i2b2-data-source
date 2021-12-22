package datasource

import (
	"encoding/json"
	"fmt"

	"github.com/ldsec/geco-i2b2-data-source/pkg/datasource/models"
	gecomodels "github.com/ldsec/geco/pkg/models"
	gecosdk "github.com/ldsec/geco/pkg/sdk"
)

// GetCohortsHandler is the OperationHandler for the getCohorts Operation.
func (ds I2b2DataSource) GetCohortsHandler(userID string, jsonParameters []byte, _ map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID) (jsonResults []byte, _ []gecosdk.DataObject, err error) {
	decodedParams := &models.GetCohortsParameters{}
	if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("decoding parameters: %v", err)
	} else if cohortResults, err := ds.GetCohorts(userID, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("getting cohorts: %v", err)
	} else if jsonResults, err = json.Marshal(cohortResults); err != nil {
		return nil, nil, fmt.Errorf("encoding results: %v", err)
	}
	return
}

// GetCohorts retrieves the list of cohorts of the user.
func (ds I2b2DataSource) GetCohorts(userID string, params *models.GetCohortsParameters) (results *models.CohortResults, err error) {
	limit := 10
	if params.Limit > 0 {
		limit = params.Limit
	}

	dbCohorts, err := ds.db.GetCohorts(userID, limit)
	if err != nil {
		return nil, fmt.Errorf("retrieving cohorts from database: %v", err)
	}

	results = new(models.CohortResults)
	results.Cohorts = make([]models.Cohort, 0, len(dbCohorts))
	for _, dbCohort := range dbCohorts {
		results.Cohorts = append(results.Cohorts, models.NewCohortFromDbModel(dbCohort))
	}

	return
}

// AddCohortHandler is the OperationHandler for the addCohort Operation.
func (ds I2b2DataSource) AddCohortHandler(userID string, jsonParameters []byte, _ map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID) (_ []byte, _ []gecosdk.DataObject, err error) {
	decodedParams := &models.AddDeleteCohortParameters{}
	if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("decoding parameters: %v", err)
	} else if err := ds.AddCohort(userID, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("adding cohort: %v", err)
	}
	return
}

// AddCohort adds a cohort.
func (ds I2b2DataSource) AddCohort(userID string, params *models.AddDeleteCohortParameters) error {
	if err := ds.db.AddCohort(userID, params.Name, params.ExploreQueryID); err != nil {
		return fmt.Errorf("adding cohort to database: %v", err)
	}
	return nil
}

// DeleteCohortHandler is the OperationHandler for the deleteCohort Operation.
func (ds I2b2DataSource) DeleteCohortHandler(userID string, jsonParameters []byte, _ map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID) (_ []byte, _ []gecosdk.DataObject, err error) {
	decodedParams := &models.AddDeleteCohortParameters{}
	if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("decoding parameters: %v", err)
	} else if err := ds.DeleteCohort(userID, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("deleting cohort: %v", err)
	}
	return
}

// DeleteCohort deletes a cohort.
func (ds I2b2DataSource) DeleteCohort(userID string, params *models.AddDeleteCohortParameters) error {
	if err := ds.db.DeleteCohort(userID, params.Name, params.ExploreQueryID); err != nil {
		return fmt.Errorf("deleting cohort from database: %v", err)
	}
	return nil
}
