package datasource

import (
	gecomodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	gecosdk "github.com/tuneinsight/sdk-datasource/pkg/sdk"
)

// Operation is an operation of the data source supported by I2b2DataSource.Query.
type Operation string

// Enumerated values for Operation.
const (
	OperationSearchConcept   Operation = "searchConcept"
	OperationSearchModifier  Operation = "searchModifier"
	OperationSearchOntology  Operation = "searchOntology"
	OperationExploreQuery    Operation = "exploreQuery"
	OperationGetCohorts      Operation = "getCohorts"
	OperationAddCohort       Operation = "addCohort"
	OperationDeleteCohort    Operation = "deleteCohort"
	OperationSurvivalQuery   Operation = "survivalQuery"
	OperationStatisticsQuery Operation = "statisticsQuery"
)

// OperationHandler is a handler function for an operation of the data source supported by I2b2DataSource.Query.
type OperationHandler func(
	userID string, jsonParameters []byte, outputDataObjectsSharedIDs map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID,
) (
	jsonResults []byte, outputDataObjects []gecosdk.DataObject, err error,
)
