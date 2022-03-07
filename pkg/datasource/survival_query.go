package datasource

import (
	"encoding/json"
	"fmt"
	"sort"
	"strconv"
	"sync"

	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/database"

	"github.com/sirupsen/logrus"

	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/models"
	gecomodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk"
	gecosdk "github.com/tuneinsight/sdk-datasource/pkg/sdk"
)

// Names of output data objects.
const (
	outputNameSurvivalQueryInitialCounts          sdk.OutputDataObjectName = "initialCounts"
	outputNameSurvivalQueryEventsOfInterestCounts sdk.OutputDataObjectName = "eventsOfInterestCounts"
	outputNameSurvivalQueryCensoringEventsCounts  sdk.OutputDataObjectName = "censoringEventsCounts"
)

// SurvivalQueryHandler is the OperationHandler for the OperationSurvivalQuery Operation.
func (ds I2b2DataSource) SurvivalQueryHandler(userID string, jsonParameters []byte, outputDataObjectsSharedIDs map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID) (jsonResults []byte, outputDataObjects []gecosdk.DataObject, err error) {

	decodedParams := &models.SurvivalQueryParameters{}
	if outputDataObjectsSharedIDs[outputNameSurvivalQueryInitialCounts] == "" ||
		outputDataObjectsSharedIDs[outputNameSurvivalQueryEventsOfInterestCounts] == "" ||
		outputDataObjectsSharedIDs[outputNameSurvivalQueryCensoringEventsCounts] == "" {
		return nil, nil, fmt.Errorf("missing output data object name")
	} else if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("decoding parameters: %v", err)
	}

	if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("decoding parameters: %v", err)
	} else if initialCounts, eventsOfInterestCounts, censoringEventsCounts, err := ds.SurvivalQuery(userID, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("executing query: %v", err)
	} else {
		// wrap results in data objects
		outputDataObjects = []gecosdk.DataObject{
			{
				OutputName: outputNameSurvivalQueryInitialCounts,
				SharedID:   outputDataObjectsSharedIDs[outputNameSurvivalQueryInitialCounts],
				IntVector:  initialCounts,
			}, {
				OutputName: outputNameSurvivalQueryEventsOfInterestCounts,
				SharedID:   outputDataObjectsSharedIDs[outputNameSurvivalQueryEventsOfInterestCounts],
				IntVector:  eventsOfInterestCounts,
			}, {
				OutputName: outputNameSurvivalQueryCensoringEventsCounts,
				SharedID:   outputDataObjectsSharedIDs[outputNameSurvivalQueryCensoringEventsCounts],
				IntVector:  censoringEventsCounts,
			},
		}
	}
	return
}

// SurvivalQuery makes a survival query.
// The returned @initialCounts is a slice whose elements are the initial count values for each subgroup.
// The returned @eventsOfInterestCounts and @censoringEventsCounts are slices containing the flattened counts of all subgroups.
// E.g., if @initialCounts contains 2 elements, and @eventsOfInterestCounts and @censoringEventsCounts contain n elements each,
// the elements from 0 to n/2 - 1 refer to subgroup 0, and the elements from n/2 to n-1 refer to subgroup 1.
func (ds I2b2DataSource) SurvivalQuery(userID string, params *models.SurvivalQueryParameters) (initialCounts, eventsOfInterestCounts, censoringEventsCounts []int64, err error) {

	// validating params
	err = params.Validate()
	if err != nil {
		return nil, nil, nil, fmt.Errorf("while validating parameters for survival query %s: %v", params.ID, err)
	}

	// getting cohort
	logrus.Info("checking cohort's existence")
	cohort, err := ds.db.GetCohort(params.CohortName, params.CohortQueryID)

	if err != nil {
		return nil, nil, nil, fmt.Errorf("while retrieving cohort (%s, %s) for survival query %s: %v", params.CohortName, params.CohortQueryID, params.ID, err)
	} else if cohort == nil || cohort.ExploreQuery.UserID != userID {
		return nil, nil, nil, fmt.Errorf("requested cohort (%s, %s) for survival query %s not found", params.CohortName, params.CohortQueryID, params.ID)
	}
	logrus.Info("cohort found")

	cohortPanel := models.Panel{
		Not:         false,
		Timing:      models.TimingAny,
		CohortItems: []string{"patient_set_coll_id:" + strconv.FormatInt(cohort.ExploreQuery.ResultI2b2PatientSetID.Int64, 10)},
	}

	startConceptPanel := models.Panel{
		Not:    false,
		Timing: models.TimingAny,
		ConceptItems: []models.ConceptItem{
			{
				QueryTerm: params.StartConcept,
			},
		},
	}

	eventGroups := make(models.EventGroups, 0)
	timeLimitInDays := params.TimeLimitInDays()

	startConceptCodes, startModifierCodes, endConceptCodes, endModifierCodes, err := ds.getEventCodes(params.StartConcept, params.StartModifier, params.EndConcept, params.EndModifier)
	if err != nil {
		return nil, nil, nil, fmt.Errorf("while retrieving concept codes and patient indices: %v", err)
	}

	subGroupsDefinitions := params.SubGroupsDefinitions
	if subGroupsDefinitions == nil || len(subGroupsDefinitions) == 0 {
		subGroupsDefinitions = []*models.SubGroupDefinition{
			{
				Name:   "Full cohort",
				Timing: models.TimingAny,
			},
		}
	} else if len(subGroupsDefinitions) > 4 {
		return nil, nil, nil, fmt.Errorf("too many subgroups (%d), max: 4", len(subGroupsDefinitions))
	}

	waitGroup := &sync.WaitGroup{}
	waitGroup.Add(len(subGroupsDefinitions))
	channels := make([]chan struct {
		*models.EventGroup
	}, len(subGroupsDefinitions))
	errChan := make(chan error, len(subGroupsDefinitions))
	signal := make(chan struct{})

	for i, subGroupDefinition := range subGroupsDefinitions {
		channels[i] = make(chan struct {
			*models.EventGroup
		}, 1)
		go func(i int, subGroupDefinition *models.SubGroupDefinition) {
			defer waitGroup.Done()

			newEventGroup := &models.EventGroup{GroupID: subGroupDefinition.Name}

			panels := append(subGroupDefinition.Panels, cohortPanel, startConceptPanel)

			logrus.Infof("survival analysis: I2B2 explore for subgroup %d", i)
			logrus.Tracef("survival analysis: panels %+v", panels)
			_, _, patientList, err := ds.ExploreQuery(&models.ExploreQueryParameters{
				ID: params.ID + "_SUBGROUP_" + strconv.Itoa(i),
				Definition: models.ExploreQueryDefinition{
					Timing: subGroupDefinition.Timing,
					Panels: panels,
				},
			})

			if err != nil {
				returnedErr := fmt.Errorf("during subgroup explore procedure")
				logrus.Errorf("%v: %v", returnedErr, err)
				errChan <- returnedErr
				return
			}
			logrus.Infof("survival analysis: successful I2B2 explore query %d", i)
			logrus.Debugf("survival analysis: there are %d patients in the subgroup", len(patientList))

			// --- build time points

			timePointsEventsMap, patientWithoutStartEvent, patientWithoutEndEvent, err := ds.db.BuildTimePoints(
				patientList,
				startConceptCodes,
				startModifierCodes,
				params.StartsWhen == models.WhenEarliest,
				endConceptCodes,
				endModifierCodes,
				params.EndsWhen == models.WhenEarliest,
				timeLimitInDays,
			)

			if err != nil {
				logrus.Errorf("error while getting building time points: %v", err)
				err = fmt.Errorf("error while getting building time points")
				errChan <- err
				return
			}
			logrus.Debugf("survival analysis: found %d patients without the start event", len(patientWithoutStartEvent))
			logrus.Debugf("survival analysis: found %d patients without the end (censoring or of interest) event", len(patientWithoutEndEvent))
			timePoints := timePointMapToList(timePointsEventsMap)

			// --- initial count
			if len(patientList) < len(patientWithoutStartEvent) {
				logrus.Errorf("length of the patient list %d cannot be smaller than this of patients without start event %d", len(patientList), len(patientWithoutStartEvent))
				err = fmt.Errorf("while computing initial count")
				errChan <- err
				return
			}
			newEventGroup.InitialCount = int64(len(patientList) - len(patientWithoutStartEvent))

			// --- change time granularity
			sqlTimePoints, err := timePoints.Bin(params.TimeGranularity)
			if err != nil {
				logrus.Error("error while changing granularity")
				errChan <- err
			}
			logrus.Debugf("survival analysis: changed resolution for %s,  got %d timepoints", params.TimeGranularity, len(sqlTimePoints))
			logrus.Tracef("survival analysis: time points with resolution %s %+v", params.TimeGranularity, sqlTimePoints)

			// --- expand
			sqlTimePoints, err = sqlTimePoints.Expand(int(timeLimitInDays), params.TimeGranularity)
			if err != nil {
				err = fmt.Errorf("while expanding: %v", err)
				errChan <- err
			}
			logrus.Debugf("survival analysis: expanded to %d time points", len(sqlTimePoints))
			logrus.Tracef("survival analysis: expanded time points %v", sqlTimePoints)

			for _, sqlTimePoint := range sqlTimePoints {
				newEventGroup.TimePointResults = append(newEventGroup.TimePointResults, &models.TimePointResult{
					TimePoint: sqlTimePoint.Time,
					Result: models.Result{
						EventValueAgg:     sqlTimePoint.Events.EventsOfInterest,
						CensoringValueAgg: sqlTimePoint.Events.CensoringEvents,
					}})

			}

			logrus.Tracef("survival analysis: event group %v", newEventGroup)
			channels[i] <- struct {
				*models.EventGroup
			}{newEventGroup}
		}(i, subGroupDefinition)
	}

	go func() {
		waitGroup.Wait()
		signal <- struct{}{}
	}()
	select {
	case err := <-errChan:
		return nil, nil, nil, err
	case <-signal:
		break
	}
	for _, channel := range channels {
		chanResult := <-channel
		eventGroups = append(eventGroups, chanResult.EventGroup)
	}

	for _, group := range eventGroups {
		logrus.Tracef("survival analysis: eventGroup %v", group)
	}

	initialCounts, eventsOfInterestCounts, censoringEventsCounts, err = eventGroups.SortAndFlatten()
	if err != nil {
		logrus.Errorf("during sorting and flattening: %v", err)
		err = fmt.Errorf("during aggregation and keyswitch")
	}
	return
}

func (ds I2b2DataSource) getEventCodes(startConcept string, startModifier *models.SurvivalQueryModifier, endConcept string, endModifier *models.SurvivalQueryModifier) (startConceptCodes, startModifierCodes, endConceptCodes, endModifierCodes []string, err error) {

	logrus.Info("survival analysis: get concept and modifier codes")

	startConceptCodes, err = ds.db.GetConceptCodes(startConcept)
	if err != nil {
		err = fmt.Errorf("while retrieving start concept code: %v", err)
		return
	}

	if startModifier == nil {
		startModifierCodes = []string{"@"}
	} else {
		startModifierCodes, err = ds.db.GetModifierCodes(startModifier.ModifierKey, startModifier.AppliedPath)
	}
	if err != nil {
		err = fmt.Errorf("while retrieving start modifier code: %v", err)
		return
	}

	endConceptCodes, err = ds.db.GetConceptCodes(endConcept)
	if err != nil {
		err = fmt.Errorf("while retrieving end concept code: %v", err)
		return
	}

	if endModifier == nil {
		endModifierCodes = []string{"@"}
	} else {
		endModifierCodes, err = ds.db.GetModifierCodes(endModifier.ModifierKey, endModifier.AppliedPath)
	}
	if err != nil {
		err = fmt.Errorf("while retrieving end modifier code: %v", err)
		return
	}
	logrus.Info("survival analysis: got concept and modifier codes")
	return
}

// timePointMapToList takes the relative-time-to-event-aggregates map and put its content in a list of TimePoint.
// A TimePoint structure contains the same information as the event aggregates plus a field referring to the relative time.
func timePointMapToList(timePointsMap map[int64]*database.Events) (list models.TimePoints) {
	list = make(models.TimePoints, 0, len(timePointsMap))
	for relativeTime, event := range timePointsMap {
		list = append(list, models.TimePoint{
			Time: relativeTime,
			Events: models.Events{
				EventsOfInterest: event.EventsOfInterest,
				CensoringEvents:  event.CensoringEvents,
			},
		})
	}

	sort.Slice(list, func(i, j int) bool {
		return list[i].Time < list[j].Time
	})

	return
}
