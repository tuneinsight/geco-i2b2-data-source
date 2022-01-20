package models

import (
	"encoding/json"

	"github.com/ldsec/geco-i2b2-data-source/pkg/datasource/database"
)

// --- parameters

// GetCohortsParameters is the parameter for the GetCohorts operation.
type GetCohortsParameters struct {
	Limit int
}

// AddDeleteCohortParameters is the parameter for the AddCohort and DeleteCohort operations.
type AddDeleteCohortParameters struct {
	Name           string
	ExploreQueryID string
}

// --- results

// CohortResults is the result of the GetCohorts operation.
type CohortResults struct {
	Cohorts []Cohort
}

// Cohort is a result part of the GetCohorts operation.
type Cohort struct {
	Name         string
	CreationDate string
	ExploreQuery struct {
		ID                         string
		CreationDate               string
		Status                     string
		Definition                 ExploreQueryDefinition
		OutputDataObjectsSharedIDs struct {
			Count       string
			PatientList string
		}
	}
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
