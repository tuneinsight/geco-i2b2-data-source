package models

import (
	"fmt"
	"strings"

	gecomodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	gecosdk "github.com/tuneinsight/sdk-datasource/pkg/sdk"
)

// SurvivalQueryParameters are the parameters for the OperationSurvivalQuery operation.
type SurvivalQueryParameters struct {

	// ID
	// Required: true
	// Pattern: ^[\w:-]+$
	ID string `json:"ID"`

	// cohort query ID
	// Required: true
	// Pattern: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i
	CohortQueryID string `json:"cohortQueryID"`

	// end concept
	// Required: true
	// Pattern: ^\/$|^((\/[^\/]+)+\/?)$
	EndConcept string `json:"endConcept"`

	// end modifier
	EndModifier *SurvivalQueryModifier `json:"endModifier,omitempty"`

	// ends when
	// Required: true
	// Enum: [earliest latest]
	EndsWhen string `json:"endsWhen"`

	// start concept
	// Required: true
	// Pattern: ^\/$|^((\/[^\/]+)+\/?)$
	StartConcept string `json:"startConcept"`

	// start modifier
	StartModifier *SurvivalQueryModifier `json:"startModifier,omitempty"`

	// starts when
	// Required: true
	// Enum: [earliest latest]
	StartsWhen string `json:"startsWhen"`

	// sub group definitions
	// Max Items: 4
	SubGroupsDefinitions []*SubGroupDefinition `json:"subGroupsDefinitions"`

	// time granularity
	// Required: true
	// Enum: [day week month year]
	TimeGranularity string `json:"timeGranularity"`

	// time limit
	// Required: true
	// Minimum: 1
	TimeLimit int64 `json:"timeLimit"`

	// OutputDataObjectsSharedIDs is a map of output data object names to their shared IDs.
	OutputDataObjectsSharedIDs map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID `json:"outputDataObjectsSharedIDs"`
}

const (

	// WhenEarliest captures enum value "earliest"
	WhenEarliest string = "earliest"

	// WhenLatest captures enum value "latest"
	WhenLatest string = "latest"
)

// SurvivalQueryModifier is a modifier used in a survival query.
type SurvivalQueryModifier struct {

	// applied path
	// Required: true
	// Pattern: ^((\/[^\/]+)+\/%?)$
	AppliedPath string `json:"appliedPath"`

	// modifier key
	// Required: true
	// Pattern: ^((\/[^\/]+)+\/)$
	ModifierKey string `json:"modifierKey"`
}

// SubGroupDefinition is the definition of a subgroup used in a survival query.
type SubGroupDefinition struct {

	// group name
	// Required: true
	// Pattern: ^\w+$
	Name string `json:"name"`

	// explore query identifying the subgroup
	// Required: true
	Constraint ExploreQueryDefinition `json:"constraint"`
}

// Validate validates SurvivalQueryParameters' fields.
func (params *SurvivalQueryParameters) Validate() error {

	params.ID = strings.TrimSpace(params.ID)
	if params.ID == "" {
		return fmt.Errorf("empty survival query ID")
	}

	params.StartConcept = strings.TrimSpace(params.StartConcept)
	if params.StartConcept == "" {
		return fmt.Errorf("emtpy start concept path, query ID: %s", params.ID)
	}
	if params.StartModifier != nil {
		params.StartModifier.ModifierKey = strings.TrimSpace(params.StartModifier.ModifierKey)
		if params.StartModifier.ModifierKey == "" {
			return fmt.Errorf("empty start modifier key, query ID: %s, start concept: %s", params.ID, params.StartConcept)
		}
		params.StartModifier.AppliedPath = strings.TrimSpace(params.StartModifier.AppliedPath)
		if params.StartModifier.AppliedPath == "" {
			return fmt.Errorf(
				"empty start modifier applied path, queryID: %s, start concept: %s, start modifier key: %s",
				params.ID, params.StartConcept,
				params.StartModifier.ModifierKey,
			)
		}
	}

	params.EndConcept = strings.TrimSpace(params.EndConcept)
	if params.EndConcept == "" {
		return fmt.Errorf("empty end concept path, query ID: %s", params.ID)
	}
	if params.EndModifier != nil {
		params.EndModifier.ModifierKey = strings.TrimSpace(params.EndModifier.ModifierKey)
		if params.EndModifier.ModifierKey == "" {
			return fmt.Errorf("empty end modifier key, query ID: %s, end concept: %s", params.ID, params.EndConcept)
		}
		params.EndModifier.AppliedPath = strings.TrimSpace(params.EndModifier.AppliedPath)
		if params.EndModifier.AppliedPath == "" {
			return fmt.Errorf(
				"empty end modifier applied path, query ID: %s, end concept: %s, end modifier key: %s",
				params.ID, params.EndConcept,
				params.EndModifier.ModifierKey,
			)
		}
	}

	params.TimeGranularity = strings.ToLower(strings.TrimSpace(params.TimeGranularity))
	if params.TimeGranularity == "" {
		return fmt.Errorf("empty granularity query ID: %s", params.ID)
	}
	if _, isIn := granularityFunctions[params.TimeGranularity]; !isIn {
		granularities := make([]string, 0, len(granularityFunctions))
		for name := range granularityFunctions {
			granularities = append(granularities, name)
		}
		return fmt.Errorf("granularity %s not implemented, must be one of %v; query ID: %s", params.TimeGranularity, granularities, params.ID)
	}
	return nil

}

// TimeLimitInDays returns the time limit in days.
func (params *SurvivalQueryParameters) TimeLimitInDays() int64 {
	return params.TimeLimit * int64(granularityValues[params.TimeGranularity])
}
