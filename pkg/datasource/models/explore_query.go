package models

import i2b2clientmodels "github.com/tuneinsight/geco-i2b2-data-source/pkg/i2b2client/models"

// --- parameters

// ExploreQueryParameters is the parameter for the ExploreQuery operation.
type ExploreQueryParameters struct {
	ID         string                 `json:"id"`
	Definition ExploreQueryDefinition `json:"definition"`
}

// ExploreQueryDefinition is the query definition of ExploreQueryParameters.
type ExploreQueryDefinition struct {
	Timing string  `json:"timing"` // any | samevisit | sameinstancenum
	Panels []Panel `json:"panels"`
}

// Panel is part of an ExploreQueryDefinition.
type Panel struct {
	Not          bool          `json:"not"`
	Timing       string        `json:"timing"`      // any | samevisit | sameinstancenum
	CohortItems  []string      `json:"cohortItems"` // contains the explore query IDs
	ConceptItems []ConceptItem `json:"conceptItems"`
}

const (

	// TimingAny captures enum value "any"
	TimingAny string = "any"

	// TimingSamevisit captures enum value "samevisit"
	TimingSamevisit string = "samevisit"

	// TimingSameinstancenum captures enum value "sameinstancenum"
	TimingSameinstancenum string = "sameinstancenum"
)

// ConceptItem is part of a Panel.
type ConceptItem struct {
	QueryTerm string `json:"queryTerm"`
	Operator  string `json:"operator"` // EQ | NE | GT | GE | LT | LE | BETWEEN | IN | LIKE[exact] | LIKE[begin] | LIKE[end] | LIKE[contains]
	Value     string `json:"value"`
	Type      string `json:"type"` // NUMBER | TEXT
	Modifier  struct {
		Key         string `json:"key"`
		AppliedPath string `json:"appliedPath"`
	} `json:"modifier"`
}

// ToI2b2APIModel converts this query definition in the i2b2 API format.
func (d ExploreQueryDefinition) ToI2b2APIModel() (i2b2ApiPanels []i2b2clientmodels.Panel, i2b2ApiTiming i2b2clientmodels.Timing) {
	i2b2ApiTiming = i2b2clientmodels.Timing(d.Timing)

	for panelIdx, panel := range d.Panels {
		var i2b2ApiItems []i2b2clientmodels.Item

		for _, item := range panel.ConceptItems {
			i2b2ApiItem := i2b2clientmodels.Item{ItemKey: i2b2clientmodels.ConvertPathToI2b2Format(item.QueryTerm)}

			if item.Operator != "" && item.Modifier.Key == "" {
				i2b2ApiItem.ConstrainByValue = &i2b2clientmodels.ConstrainByValue{
					ValueType:       item.Type,
					ValueOperator:   item.Operator,
					ValueConstraint: item.Value,
				}
			}

			if item.Modifier.Key != "" {
				i2b2ApiItem.ConstrainByModifier = &i2b2clientmodels.ConstrainByModifier{
					ModifierKey: i2b2clientmodels.ConvertPathToI2b2Format(item.Modifier.Key),
					AppliedPath: i2b2clientmodels.ConvertAppliedPathToI2b2Format(item.Modifier.AppliedPath),
				}
				if item.Operator != "" {
					i2b2ApiItem.ConstrainByModifier.ConstrainByValue = &i2b2clientmodels.ConstrainByValue{
						ValueType:       item.Type,
						ValueOperator:   item.Operator,
						ValueConstraint: item.Value,
					}
				}
			}
			i2b2ApiItems = append(i2b2ApiItems, i2b2ApiItem)
		}

		for _, cohort := range panel.CohortItems {

			i2b2ApiItems = append(i2b2ApiItems, i2b2clientmodels.Item{ItemKey: cohort})
		}

		i2b2ApiPanels = append(i2b2ApiPanels,
			i2b2clientmodels.NewPanel(panelIdx, panel.Not, i2b2clientmodels.Timing(panel.Timing), i2b2ApiItems),
		)
	}
	return
}
