package datasource

import (
	"encoding/json"
	"fmt"
	"sort"
	"strconv"
	"sync"
	"time"

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
func (ds I2b2DataSource) SurvivalQuery(userID string, params *models.SurvivalQueryParameters) (initialCounts, eventsOfInterestCounts, censoringEventsCounts []int64, err error) {

	// validating params
	err = params.Validate()
	if err != nil {
		return nil, nil, nil, fmt.Errorf("while validating parameters for survival query %s: %v", *params.ID, err)
	}

	// getting cohort
	logrus.Info("checking cohort's existence")
	cohort, err := ds.db.GetCohort(*params.CohortName, *params.CohortQueryID)

	if err != nil {
		return nil, nil, nil, fmt.Errorf("while retrieving cohort (%s, %s) for survival query %s: %v", *params.CohortName, *params.CohortQueryID, *params.ID, err)
	} else if cohort == nil || cohort.ExploreQuery.UserID != userID {
		return nil, nil, nil, fmt.Errorf("requested cohort (%s, %s) for survival query %s not found", *params.CohortName, *params.CohortQueryID, *params.ID)
	}
	logrus.Info("cohort found")

	cohortPanel := models.Panel{
		Not:         false,
		Timing:      models.TimingAny,
		CohortItems: []string{strconv.FormatInt(cohort.ExploreQuery.ResultI2b2PatientSetID.Int64, 10)},
	}

	startConceptPanel := models.Panel{
		Not:    false,
		Timing: models.TimingAny,
		ConceptItems: []models.ConceptItem{
			{
				QueryTerm: *params.StartConcept,
			},
		},
	}

	eventGroups := make(models.EventGroups, 0)
	timeLimitInDays := params.TimeLimitInDays()

	startConceptCodes, startModifierCodes, endConceptCodes, endModifierCodes, err := ds.getEventCodes(*params.StartConcept, params.StartModifier, *params.EndConcept, params.EndModifier)
	if err != nil {
		return nil, nil, nil, fmt.Errorf("while retrieving concept codes and patient indices: %v", err)
	}

	subGroupsDefinitions := params.SubGroupsDefinitions
	if subGroupsDefinitions == nil || len(subGroupsDefinitions) == 0 {
		subGroupsDefinitions = []*models.SubGroupDefinition{
			{
				GroupName:      "Full cohort",
				SubGroupTiming: models.TimingAny,
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

			newEventGroup := &models.EventGroup{GroupID: subGroupDefinition.GroupName}

			panels := append(subGroupDefinition.Panels, cohortPanel, startConceptPanel)

			logrus.Infof("survival analysis: I2B2 explore for subgroup %d", i)
			logrus.Tracef("survival analysis: panels %+v", panels)
			_, _, patientList, err := ds.ExploreQuery(&models.ExploreQueryParameters{
				ID: *params.ID + "_SUBGROUP_" + strconv.Itoa(i),
				Definition: models.ExploreQueryDefinition{
					Timing: subGroupDefinition.SubGroupTiming,
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

			timePointsEventsMap, patientWithoutStartEvent, patientWithoutEndEvent, err := ds.buildTimePoints(
				patientList,
				startConceptCodes,
				startModifierCodes,
				*params.StartsWhen == models.WhenEarliest,
				endConceptCodes,
				endModifierCodes,
				*params.EndsWhen == models.WhenEarliest,
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
			sqlTimePoints, err := timePoints.Bin(*params.TimeGranularity)
			if err != nil {
				logrus.Error("error while changing granularity")
				errChan <- err
			}
			logrus.Debugf("survival analysis: changed resolution for %s,  got %d timepoints", *params.TimeGranularity, len(sqlTimePoints))
			logrus.Tracef("survival analysis: time points with resolution %s %+v", *params.TimeGranularity, sqlTimePoints)

			// --- expand
			sqlTimePoints, err = sqlTimePoints.Expand(int(timeLimitInDays), *params.TimeGranularity)
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
		logrus.Tracef("Survival analysis: eventGroup %v", group)
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
		startModifierCodes, err = ds.db.GetModifierCodes(*startModifier.ModifierKey, *startModifier.AppliedPath)
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
		endModifierCodes, err = ds.db.GetModifierCodes(*endModifier.ModifierKey, *endModifier.AppliedPath)
	}
	if err != nil {
		err = fmt.Errorf("while retrieving end modifier code: %v", err)
		return
	}
	logrus.Info("survival analysis: got concept and modifier codes")
	return
}

// buildTimePoints runs the SQL queries, process their results to build sequential data and aggregate them.
func (ds I2b2DataSource) buildTimePoints(
	patientSet []int64,
	startConceptCodes []string,
	startModifierCodes []string,
	startEarliest bool,
	endConceptCodes []string,
	endModifierCodes []string,
	endEarliest bool,
	maxLimit int64,
) (
	eventAggregates map[int64]*models.Events,
	patientWithoutStartEvent map[int64]struct{},
	patientWithoutAnyEndEvent map[int64]struct{},
	err error,
) {

	patientsToStartEvent, patientWithoutStartEvent, err := ds.db.StartEvent(patientSet, startConceptCodes, startModifierCodes, startEarliest)
	if err != nil {
		return
	}

	patientsToEndEvents, err := ds.db.EndEvents(patientsToStartEvent, endConceptCodes, endModifierCodes)
	if err != nil {
		return
	}

	patientsWithoutEnd, startToEndEvent, err := patientAndEndEvents(patientsToStartEvent, patientsToEndEvents, endEarliest)
	if err != nil {
		return
	}

	patientsToCensoringEvent, patientWithoutAnyEndEvent, err := ds.db.CensoringEvent(patientsToStartEvent, patientsWithoutEnd, endConceptCodes, endModifierCodes)
	if err != nil {
		return
	}

	startToCensoringEvent, err := patientAndCensoring(patientsToStartEvent, patientsWithoutEnd, patientsToCensoringEvent)
	if err != nil {
		return
	}

	eventAggregates, err = compileTimePoints(startToEndEvent, startToCensoringEvent, maxLimit)
	if err != nil {
		return
	}

	return
}

// patientAndEndEvents takes as input the patient-to-start-event map and the patient-to-end-event-candidates.
// For each patient, in the first map, it checks its presence in the second one.
// endEarliest defines if it must take the earliest or the latest among candidates. Candidates must occur strictly after the start event, an error is thrown otherwise.
// The list of candidate events is not expected to be empty, an error is thrown if it is the case.
// The patient-to-difference-in-day map is returned alongside the list of patients present in the patient-to-start-event map and absent from patient-to-end-event.
func patientAndEndEvents(startEvent map[int64]time.Time, endEvents map[int64][]time.Time, endEarliest bool) (map[int64]struct{}, map[int64]int64, error) {

	patientsWithoutEndEvent := make(map[int64]struct{}, len(startEvent))
	patientsWithStartAndEndEvents := make(map[int64]int64, len(startEvent))
	for patientID, startDate := range startEvent {
		if endDates, isIn := endEvents[patientID]; isIn {
			if endDates == nil {
				err := fmt.Errorf("unexpected nil end-date list for patient %d", patientID)
				return nil, nil, err
			}
			nofEndDates := len(endDates)
			if nofEndDates == 0 {
				err := fmt.Errorf("unexpected empty end-date list for patient %d", patientID)
				return nil, nil, err
			}
			sort.Slice(endDates, func(i, j int) bool {
				return endDates[i].Before(endDates[j])
			})

			var endDate time.Time
			if endEarliest {
				endDate = endDates[0]
			} else {
				endDate = endDates[nofEndDates-1]
			}

			diffInHours := endDate.Sub(startDate).Hours()
			truncatedDiff := int64(diffInHours)
			if remaining := truncatedDiff % 24; remaining != 0 {
				err := fmt.Errorf("the remaining of the time difference must be divisible by 24, the remaining is actually %d", remaining)
				return nil, nil, err
			}
			numberInDays := truncatedDiff / 24

			if numberInDays <= 0 {
				err := fmt.Errorf("the difference is expected to be strictly greater than 0, actually got %d", numberInDays)
				return nil, nil, err
			}
			patientsWithStartAndEndEvents[patientID] = numberInDays

		} else {
			patientsWithoutEndEvent[patientID] = struct{}{}
		}
	}
	return patientsWithoutEndEvent, patientsWithStartAndEndEvents, nil
}

// patientAndCensoring takes as input the patient-to-start-event, the patient-without-end-event set and the patient-to-censoring map,
// and computes the difference in day for each patient in the patient-without-end-event between the censoring time taken from the second map
// and the start time taken from the first map. The set of patients without end event is expected to be a subset of the patient-to-start-event keys and
// censoring events must happen strictly after the start event, an error is thrown otherwise.
// The patient-to-difference-in-day (for censoring events) is returned.
func patientAndCensoring(startEvent map[int64]time.Time, patientsWithoutEndEvent map[int64]struct{}, patientWithCensoring map[int64]time.Time) (map[int64]int64, error) {
	patientsWithStartAndCensoring := make(map[int64]int64, len(startEvent))
	for patientID := range patientsWithoutEndEvent {
		if endDate, isIn := patientWithCensoring[patientID]; isIn {
			startDate, isFound := startEvent[patientID]
			if !isFound {
				err := fmt.Errorf("the set of patients without the end event of interest must be a subset of the start-event keys: patient %d found in patients without events of interest, but is not a start-event key", patientID)
				return nil, err
			}

			diffInHours := endDate.Sub(startDate).Hours()
			truncatedDiff := int64(diffInHours)
			if remaining := truncatedDiff % 24; remaining != 0 {
				err := fmt.Errorf("the remaining of the time difference must be divisible by 24, the remaining is actually %d", remaining)
				return nil, err
			}
			numberInDays := truncatedDiff / 24

			if numberInDays <= 0 {
				err := fmt.Errorf("the difference is expected to be strictly greater than 0, actually got %d", numberInDays)
				return nil, err
			}
			patientsWithStartAndCensoring[patientID] = numberInDays
		}
	}
	return patientsWithStartAndCensoring, nil
}

// compileTimePoints takes as input the patient-to-end-event and the patient-to-censoring-event maps and aggregates te number of events, grouped by difference in days (aka relative times).
// If a relative time is strictly bigger than the max limit defined by the user, it is ignored. If the relative time or the maximum limit is smaller or equal to  zero, an error is thrown.
func compileTimePoints(patientWithEndEvents, patientWithCensoringEvents map[int64]int64, maxLimit int64) (map[int64]*models.Events, error) {
	if maxLimit <= 0 {
		err := fmt.Errorf("user-defined maximum limit %d must be strictly greater than 0", maxLimit)
		return nil, err
	}
	timePointTable := make(map[int64]*models.Events, int(maxLimit))
	for _, timePoint := range patientWithEndEvents {
		if timePoint > maxLimit {
			logrus.Tracef("Survival analysis: timepoint: timepoint %d beyond user-defined limit %d; dropped", timePoint, maxLimit)
			continue
		}
		if timePoint <= 0 {
			err := fmt.Errorf("while computing events aggregates: relative time in patients with end event must be strictly greater than 0, got %d", timePoint)
			return nil, err
		}
		if _, isIn := timePointTable[timePoint]; !isIn {
			timePointTable[timePoint] = &models.Events{
				EventsOfInterest: 1,
				CensoringEvents:  0,
			}
		} else {
			elm := timePointTable[timePoint]
			elm.EventsOfInterest++
		}
	}

	for _, timePoint := range patientWithCensoringEvents {
		if timePoint > maxLimit {
			logrus.Tracef("Survival analysis: timepoint: timepoint %d beyond user-defined limit %d; dropped", timePoint, maxLimit)
			continue
		}
		if timePoint <= 0 {
			err := fmt.Errorf("while computing events aggregates: relative time in patients with censoring event must be strictly greater than 0, got %d", timePoint)
			return nil, err
		}
		if _, isIn := timePointTable[timePoint]; !isIn {
			timePointTable[timePoint] = &models.Events{
				EventsOfInterest: 0,
				CensoringEvents:  1,
			}
		} else {
			elm := timePointTable[timePoint]
			elm.CensoringEvents++
		}
	}
	return timePointTable, nil
}

// timePointMapToList takes the relative-time-to-event-aggregates map and put its content in a list of TimePoint.
// A TimePoint structure contains the same information as the event aggregates plus a field referring to the relative time.
func timePointMapToList(timePointsMap map[int64]*models.Events) (list models.TimePoints) {
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
