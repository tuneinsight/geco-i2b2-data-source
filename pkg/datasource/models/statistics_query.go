package models

import (
	"fmt"
	"strings"
)

// StatisticsQueryParameters are the parameters for the OperationStatisticsQuery operation.
type StatisticsQueryParameters struct {

	// ID
	// Required: true
	// Pattern: ^[\w:-]+$
	ID string `json:"ID"`

	// CohortQueryID
	// Required: true
	// Pattern: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i
	CohortQueryID string `json:"cohortQueryID"`

	isPanelEmpty bool

	// I2B2 Panels defining the analyzed population.
	Panels []*Panel

	// query Timing
	// Enum: [any samevisit sameinstance]
	Timing string `json:"timing,omitempty"`

	// Concepts contains the analytes.
	Concepts []*ConceptItem

	// BucketSize is the bucket size for each analyte.
	BucketSize float64 `json:"bucketSize"`

	// MinObservation is the global minimal observation for each analyte.
	MinObservation float64 `json:"minObservation"`
}

// Validate validates StatisticsQueryParameters' fields.
func (params *StatisticsQueryParameters) Validate() error {

	params.ID = strings.TrimSpace(params.ID)
	if params.ID == "" {
		return fmt.Errorf("empty statistics query ID")
	}

	for _, concept := range params.Concepts {
		concept.QueryTerm = strings.TrimSpace(concept.QueryTerm)
		if concept.QueryTerm == "" {
			return fmt.Errorf("emtpy concept path, statistics query ID: %s", params.ID)
		}

		if concept.Modifier != nil {
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
