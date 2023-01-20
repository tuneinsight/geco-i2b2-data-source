package models

import (
	"fmt"
	"strings"

	gecomodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	gecosdk "github.com/tuneinsight/sdk-datasource/pkg/sdk"
)

// StatisticsQueryParameters are the parameters for the OperationStatisticsQuery operation.
type StatisticsQueryParameters struct {

	// ID
	// Required: true
	// Pattern: ^[\w:-]+$
	ID string `json:"ID"`

	// Constraint is the ExploreQueryDefinition defining the analyzed population
	Constraint ExploreQueryDefinition `json:"constraint"`

	// Analytes contains the concepts used as analytes.
	Analytes []*ConceptItem `json:"analytes"`

	// BucketSize is the bucket size for each analyte.
	BucketSize float64 `json:"bucketSize"`

	// MinObservations is the total minimal number of observations for each analyte.
	MinObservations int64 `json:"minObservations"`

	// OutputDataObjectsSharedIDs is a map of output data object names to their shared IDs.`json:"definition"`
	OutputDataObjectsSharedIDs map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID `json:"outputDataObjectsSharedIDs"`
}

// Validate validates StatisticsQueryParameters fields.
func (params *StatisticsQueryParameters) Validate() error {

	params.ID = strings.TrimSpace(params.ID)
	if params.ID == "" {
		return fmt.Errorf("empty statistics query ID")
	}

	if err := params.Constraint.Validate(); err != nil {
		return fmt.Errorf("while validating constraint of statistics query: %v", err)
	}

	for _, concept := range params.Analytes {
		concept.QueryTerm = strings.TrimSpace(concept.QueryTerm)
		if concept.QueryTerm == "" {
			return fmt.Errorf("emtpy concept path, statistics query ID: %s", params.ID)
		}

		if concept.Modifier.Key == "" {
			concept.Modifier.Key = strings.TrimSpace(concept.Modifier.Key)
			concept.Modifier.AppliedPath = strings.TrimSpace(concept.Modifier.AppliedPath)
			if concept.Modifier.Key == "" {
				return fmt.Errorf("empty modifier path, statistics query ID: %s", params.ID)
			} else if concept.Modifier.AppliedPath == "" {
				return fmt.Errorf("empty modifier applied path, statistics query ID: %s", params.ID)
			}
		}

	}

	return nil
}

// Bucket represents a bucket.
// The lower bound is inclusive, the higher bound is exclusive: [lower bound, higher bound[
type Bucket struct {
	LowerBound  float64
	HigherBound float64
	Count       int64 // contains the count of subjects in this bucket
}

// StatsResult contains the information to build the histogram of observations for an analyte.
type StatsResult struct {
	Buckets []*Bucket
	Unit    string
	//concept or modifier name
	AnalyteName string
}
