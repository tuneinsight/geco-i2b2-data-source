package models

import i2b2apimodels "github.com/ldsec/geco-i2b2-data-source/pkg/i2b2api/models"

// --- parameters

type ExploreQueryParameters struct {
	Id string
	Definition ExploreQueryDefinition
}

type ExploreQueryDefinition struct {
	Timing string // any | samevisit | sameinstancenum
	Panels []Panel
}

type Panel struct {
	Not          bool
	Timing       string // any | samevisit | sameinstancenum
	CohortItems  []string
	ConceptItems []ConceptItem
}

type ConceptItem struct {
	QueryTerm string
	Operator  string // EQ | NE | GT | GE | LT | LE | BETWEEN | IN | LIKE[exact] | LIKE[begin] | LIKE[end] | LIKE[contains]
	Value     string
	Type      string // NUMBER | TEXT
	Modifier  struct {
		Key         string
		AppliedPath string
	}
}

func (d ExploreQueryDefinition) ToI2b2APIModel() (i2b2ApiPanels []i2b2apimodels.Panel, i2b2ApiTiming i2b2apimodels.Timing) {
	i2b2ApiTiming = i2b2apimodels.Timing(d.Timing)

	for panelIdx, panel := range d.Panels {
		var i2b2ApiItems []i2b2apimodels.Item

		for _, item := range panel.ConceptItems {
			i2b2ApiItem := i2b2apimodels.Item{ItemKey: i2b2apimodels.ConvertPathToI2b2Format(item.QueryTerm)}

			if item.Operator != "" && item.Modifier.Key == "" {
				i2b2ApiItem.ConstrainByValue = &i2b2apimodels.ConstrainByValue{
					ValueType:       item.Type,
					ValueOperator:   item.Operator,
					ValueConstraint: item.Value,
				}
			}

			if item.Modifier.Key != "" {
				i2b2ApiItem.ConstrainByModifier = &i2b2apimodels.ConstrainByModifier{
					ModifierKey: i2b2apimodels.ConvertPathToI2b2Format(item.Modifier.Key),
					AppliedPath: i2b2apimodels.ConvertAppliedPathToI2b2Format(item.Modifier.AppliedPath),
				}
				if item.Operator != "" {
					i2b2ApiItem.ConstrainByModifier.ConstrainByValue = &i2b2apimodels.ConstrainByValue{
						ValueType:       item.Type,
						ValueOperator:   item.Operator,
						ValueConstraint: item.Value,
					}
				}
			}
			i2b2ApiItems = append(i2b2ApiItems, i2b2ApiItem)
		}

		for _, cohort := range panel.CohortItems {
			i2b2ApiItems = append(i2b2ApiItems, i2b2apimodels.Item{ItemKey: cohort})
		}

		i2b2ApiPanels = append(i2b2ApiPanels,
			i2b2apimodels.NewPanel(panelIdx, panel.Not, i2b2apimodels.Timing(panel.Timing), i2b2ApiItems),
		)
	}
	return
}
