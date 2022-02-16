package models

import (
	"encoding/json"

	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/database"
)

// --- parameters

// GetCohortsParameters is the parameter for the GetCohorts operation.
type GetCohortsParameters struct {
	Limit int `json:"limit"`
}

// AddDeleteCohortParameters is the parameter for the AddCohort and DeleteCohort operations.
type AddDeleteCohortParameters struct {
	Name           string `json:"name"`
	ExploreQueryID string `json:"exploreQueryID"`
}

// --- results

// CohortResults is the result of the GetCohorts operation.
type CohortResults struct {
	Cohorts []Cohort `json:"cohorts"`
}

// Cohort is a result part of the GetCohorts operation.
type Cohort struct {
	Name         string `json:"name"`
	CreationDate string `json:"CreationDate"`
	ExploreQuery struct {
		ID                         string                 `json:"id"`
		CreationDate               string                 `json:"creationDate"`
		Status                     string                 `json:"status"`
		Definition                 ExploreQueryDefinition `json:"definition"`
		OutputDataObjectsSharedIDs struct {
			Count       string `json:"count"`
			PatientList string `json:"patientList"`
		} `json:"outputDataObjectsSharedIDs"`
	} `json:"exploreQuery"`
}

// NewCohortFromDbModel creates a new Cohort from a database.SavedCohort.
func NewCohortFromDbModel(dbCohort database.SavedCohort) (cohort Cohort) {
	cohort.Name = dbCohort.Name
	cohort.CreationDate = dbCohort.CreateDate

	cohort.ExploreQuery.ID = dbCohort.ExploreQuery.ID
	cohort.ExploreQuery.Status = dbCohort.ExploreQuery.Status
	cohort.ExploreQuery.CreationDate = dbCohort.ExploreQuery.CreateDate
	cohort.ExploreQuery.OutputDataObjectsSharedIDs.Count = dbCohort.ExploreQuery.ResultGecoSharedIDCount.String
	cohort.ExploreQuery.OutputDataObjectsSharedIDs.PatientList = dbCohort.ExploreQuery.ResultGecoSharedIDPatientList.String

	_ = json.Unmarshal([]byte(dbCohort.ExploreQuery.Definition), &cohort.ExploreQuery.Definition)
	return cohort
}
