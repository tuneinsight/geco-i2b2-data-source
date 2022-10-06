package models

import (
	"fmt"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	i2b2clientmodels "github.com/tuneinsight/geco-i2b2-data-source/pkg/i2b2client/models"
)

const (

	// TimingAny captures enum value "any"
	TimingAny string = "any"
	// TimingSamevisit captures enum value "samevisit"
	TimingSamevisit string = "samevisit"
	// TimingSameinstancenum captures enum value "sameinstancenum"
	TimingSameinstancenum string = "sameinstancenum"

	// SequentialOperatorWhichDateStart captures enum value "STARTDATE"
	SequentialOperatorWhichDateStart = "STARTDATE"
	// SequentialOperatorWhichDateEnd captures enum value "ENDDATE"
	SequentialOperatorWhichDateEnd = "ENDDATE"
	// SequentialOperatorWhichObservationFirst captures enum value "FIRST"
	SequentialOperatorWhichObservationFirst = "FIRST"
	// SequentialOperatorWhichObservationLast captures enum value "LAST"
	SequentialOperatorWhichObservationLast = "LAST"
	// SequentialOperatorWhichObservationAny captures enum value "Any"
	SequentialOperatorWhichObservationAny = "ANY"
	// SequentialOperatorWhenLess captures enum value "LESS"
	SequentialOperatorWhenLess = "LESS"
	// SequentialOperatorWhenLessEqual captures enum value "LESSEQUAL"
	SequentialOperatorWhenLessEqual = "LESSEQUAL"
	// SequentialOperatorWhenEqual captures enum value "EQUAL"
	SequentialOperatorWhenEqual = "EQUAL"

	// SpanUnitHour captues enum value "HOUR"
	SpanUnitHour = "HOUR"
	// SpanUnitDay captues enum value "DAY"
	SpanUnitDay = "DAY"
	// SpanUnitMonth captues enum value "MONTH"
	SpanUnitMonth = "MONTH"
	// SpanUnitYear captues enum value "YEAR"
	SpanUnitYear = "YEAR"

	// SpanOperatorLess captures enum value "LESS"
	SpanOperatorLess = "LESS"
	// SpanOperatorLessEqual captures enum value "LESSEQUAL"
	SpanOperatorLessEqual = "LESSEQUAL"
	// SpanOperatorEqual captures enum value "EQUAL"
	SpanOperatorEqual = "EQUAL"
	// SpanOperatorGreaterEqual captures enum value "GREATEREQUAL"
	SpanOperatorGreaterEqual = "GREATEREQUAL"
	// SpanOperatorGreater captures enum value "GREATER"
	SpanOperatorGreater = "GREATER"
)

// --- parameters

// ExploreQueryParameters is the parameter for the ExploreQuery operation.
type ExploreQueryParameters struct {
	ID         string                 `json:"id"`
	Definition ExploreQueryDefinition `json:"definition"`
}

// ExploreQueryDefinition is the query definition of ExploreQueryParameters.
type ExploreQueryDefinition struct {
	Timing          string  `json:"timing"` // any | samevisit | sameinstancenum
	SelectionPanels []Panel `json:"selectionPanels"`

	// SequentialOperators determines the temporal relations between the SequentialPanels.
	//        The element at position i determines the relation between the panels at positions i and i + 1.
	SequentialOperators []SequentialOperator `json:"sequentialOperators"`
	SequentialPanels    []Panel              `json:"sequentialPanels"`
}

// Validate validates the ExploreQueryDefinition fields
func (d ExploreQueryDefinition) Validate() error {
	nSeqPanels := len(d.SequentialPanels)
	if nSeqPanels == 1 {
		return fmt.Errorf("query definition cannot contain only 1 sequential panel")
	}
	if nSeqTimings := len(d.SequentialOperators); nSeqPanels > 0 && nSeqTimings != nSeqPanels-1 {
		return fmt.Errorf("%d sequential timings for %d sequential panels", nSeqTimings, nSeqPanels)
	}
	for _, panel := range d.SequentialPanels {
		if len(panel.CohortItems) > 0 {
			return fmt.Errorf("cohort items cannot be used in sequential queries")
		}
	}
	return nil
}

// Panel is part of an ExploreQueryDefinition.
type Panel struct {
	Not          bool          `json:"not"`
	Timing       string        `json:"timing"`      // any | samevisit | sameinstancenum
	CohortItems  []string      `json:"cohortItems"` // contains the explore query IDs
	ConceptItems []ConceptItem `json:"conceptItems"`
}

// SequentialOperator contains the info according to which the temporal relation between two panels is determined.
//    The observations identified by the first panel occur before the observations identified by the second panel if
//    the {WhichDateFirst} of the {WhichObservationFirst} observation in the first panel
//    occurs {When} [by {Spans[0]} [and {Spans[1]}]] than
//    the {WhichDateSecond} of the {WhichObservationSecond} observation in the second panel.
type SequentialOperator struct {
	WhichDateFirst         string `json:"whichDateFirst"`         // STARTDATE | ENDDATE
	WhichObservationFirst  string `json:"whichObservationFirst"`  // FIRST | LAST | ANY
	When                   string `json:"when"`                   // LESS | LESSEQUAL | EQUAL
	WhichDateSecond        string `json:"whichDateSecond"`        // STARTDATE | ENDDATE
	WhichObservationSecond string `json:"whichObservationSecond"` // FIRST | LAST | ANY
	// Spans optionally add a time constraint to When, e.g. it specifies the difference between the time of the first panel and the time of the second panel (e.g. by 1 and 3 months).
	// It contains max 2 elements, the first one being the left endpoint of the time constraint, the second the right one.
	Spans []Span `json:"spans,omitempty"`
}

func (so *SequentialOperator) defaultValues() {
	if so.WhichDateFirst == "" {
		so.WhichDateFirst = SequentialOperatorWhichDateStart
	}
	if so.WhichObservationFirst == "" {
		so.WhichObservationFirst = SequentialOperatorWhichObservationFirst
	}
	if so.When == "" {
		so.When = SequentialOperatorWhenLess
	}
	if so.WhichDateSecond == "" {
		so.WhichDateSecond = SequentialOperatorWhichDateStart
	}
	if so.WhichObservationSecond == "" {
		so.WhichObservationSecond = SequentialOperatorWhichObservationFirst
	}
}

// Span contains the info defining one of the two endpoints of a time range.
type Span struct {
	Value    int    `json:"value"`
	Units    string `json:"units"`    // HOUR | DAY | MONTH | YEAR
	Operator string `json:"operator"` // LESS | LESSEQUAL | EQUAL | GREATEREQUAL | GREATER
}

// ConceptItem is part of a Panel.
type ConceptItem struct {
	QueryTerm string `json:"queryTerm"`
	Operator  string `json:"operator"` // EQ | NE | GT | GE | LT | LE | BETWEEN | IN | LIKE[exact] | LIKE[begin] | LIKE[end] | LIKE[contains]
	Value     string `json:"value"`
	Type      string `json:"type"` // NUMBER | TEXT
	Modifier  struct {
		Key         string `json:"key"`
		AppliedPath string `json:"appliedPath"`
	} `json:"modifier,omitempty"`
}

// ToI2b2APIModel converts this query definition in the i2b2 API format.
func (d ExploreQueryDefinition) ToI2b2APIModel() (i2b2ApiPanels []i2b2clientmodels.Panel, i2b2ApiSubqueries []i2b2clientmodels.SubQuery, i2b2ApiSubqueriesConstraints []i2b2clientmodels.SubQueryConstraint, i2b2ApiTiming i2b2clientmodels.Timing, err error) {

	if err := d.Validate(); err != nil {
		return nil, nil, nil, "", fmt.Errorf("while validating explore query definition: %v", err)
	}

	i2b2ApiTiming = i2b2clientmodels.Timing(d.Timing)
	for i, panel := range d.SelectionPanels {
		i2b2ApiPanels = append(i2b2ApiPanels, toI2b2Model(i, panel))
	}

	// embed subqueries and subquery constraints if the query contains sequential panels
	if len(d.SequentialPanels) > 0 {
		logrus.Warnf("when running a sequential query, the timings of the main query and the selection panels are set to %s", TimingAny)
		i2b2ApiTiming = i2b2clientmodels.Timing(TimingAny)
		for _, panel := range i2b2ApiPanels {
			panel.PanelTiming = TimingAny
		}

		for _, sequentialPanel := range d.SequentialPanels {
			querySequenceElement := toI2b2Model(-1, sequentialPanel)
			// for sequential query, it is necessary to override the panel timing attribute
			logrus.Warnf("the panel timing attribute of temporal sequence element set to %s", TimingSameinstancenum)
			querySequenceElement.PanelTiming = TimingSameinstancenum

			subQueryStringID := uuid.New().String()

			subquery := i2b2clientmodels.SubQuery{
				QueryType:   "EVENT",
				QueryName:   subQueryStringID,
				QueryID:     subQueryStringID,
				QueryTiming: TimingSameinstancenum,
				Panels:      []i2b2clientmodels.Panel{querySequenceElement},
			}
			i2b2ApiSubqueries = append(i2b2ApiSubqueries, subquery)
		}

		for i, sequentialOperator := range d.SequentialOperators {
			sequentialOperator.defaultValues()
			subqueryConstraint := i2b2clientmodels.SubQueryConstraint{
				Operator: sequentialOperator.When,
				FirstQuery: i2b2clientmodels.SubqueryConstraintOperand{
					QueryID:           i2b2ApiSubqueries[i].QueryID,
					AggregateOperator: sequentialOperator.WhichObservationFirst,
					JoinColumn:        sequentialOperator.WhichDateFirst,
				},
				SecondQuery: i2b2clientmodels.SubqueryConstraintOperand{
					QueryID:           i2b2ApiSubqueries[i+1].QueryID,
					AggregateOperator: sequentialOperator.WhichObservationSecond,
					JoinColumn:        sequentialOperator.WhichDateSecond,
				},
			}

			for _, span := range sequentialOperator.Spans {
				span := i2b2clientmodels.Span{
					SpanValue: span.Value,
					Units:     span.Units,
					Operator:  span.Operator,
				}
				subqueryConstraint.Spans = append(subqueryConstraint.Spans, span)

			}

			i2b2ApiSubqueriesConstraints = append(i2b2ApiSubqueriesConstraints, subqueryConstraint)
		}
	}

	return
}

func toI2b2Model(panelID int, panel Panel) (i2b2ApiPanel i2b2clientmodels.Panel) {
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

	return i2b2clientmodels.NewPanel(panelID, panel.Not, i2b2clientmodels.Timing(panel.Timing), i2b2ApiItems)
}
