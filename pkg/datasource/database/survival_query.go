package database

import (
	"fmt"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk/telemetry"
)

const dateFormat = "2006-01-02"

// GetConceptCodes returns all concept codes for a given path and its descendants.
func (db PostgresDatabase) GetConceptCodes(path string) ([]string, error) {

	tableCd, pathURI := extractTableAndURI(path)

	preparedPath := prepareLike(pathURI)

	tableName, err := db.getTableName(tableCd)
	if err != nil {
		return nil, err
	}

	description := fmt.Sprintf("getConceptCodes (table name: %s, path: %s), procedure: %s", tableName, preparedPath, "i2b2metadata.get_concept_codes")
	logrus.Debugf(" running: %s", description)

	err = db.handle.Ping()
	if err != nil {
		err = fmt.Errorf("while connecting to database to get concept codes: %v", err)
		return nil, err
	}
	rows, err := db.handle.Query("SELECT i2b2metadata.get_concept_codes($1, $2);", tableName, preparedPath)
	if err != nil {
		err = fmt.Errorf("while selecting concept codes: %v, DB operation: %s", err, description)
		logrus.Error(err)
		return nil, err
	}

	resString := new(string)
	res := make([]string, 0)
	for rows.Next() {

		err = rows.Scan(resString)
		if err != nil {
			err = fmt.Errorf("while scanning SQL record: %v, DB operation: %s", err, description)
			logrus.Error(err)
			return nil, err
		}

		res = append(res, *resString)
	}
	logrus.Tracef("concept codes are %v, DB operation: %s", res, description)
	err = rows.Close()
	if err != nil {
		err = fmt.Errorf("while closing SQL record stream: %v, DB operation: %s", err, description)
		logrus.Error(err)
		return nil, err
	}
	logrus.Debugf("successfully retrieved %d concept codes, DB operation: %s", len(res), description)

	return res, nil

}

// GetModifierCodes returns all modifier codes for a given path and its descendants, and exactly matching the appliedPath.
func (db PostgresDatabase) GetModifierCodes(path string, appliedPath string) ([]string, error) {

	tableCD, path := extractTableAndURI(path)

	preparedPath := prepareLike(path)

	tableName, err := db.getTableName(tableCD)
	if err != nil {
		return nil, err
	}

	preparedAppliedPath := prepareEqual(appliedPath)
	description := fmt.Sprintf("getModifierCodes (table name: %s, path: %s, applied path: %s), procedure: %s", tableName, preparedPath, preparedAppliedPath, "i2b2metadata.get_modifier_codes")
	logrus.Debugf("running: %s", description)

	err = db.handle.Ping()
	if err != nil {
		err = fmt.Errorf("while connecting to database to get modifier codes: %v", err)
		return nil, err
	}
	rows, err := db.handle.Query("SELECT i2b2metadata.get_modifier_codes($1, $2, $3);", tableName, preparedPath, preparedAppliedPath)
	if err != nil {
		err = fmt.Errorf("while selecting modifier codes: %v, DB operation: %s", err, description)
		return nil, err
	}

	resString := new(string)
	res := make([]string, 0)
	for rows.Next() {

		err = rows.Scan(resString)
		if err != nil {
			err = fmt.Errorf("while scanning SQL record: %v, DB operation: %s", err, description)
			return nil, err
		}

		res = append(res, *resString)
	}
	logrus.Tracef("modifier codes are %v, DB operation: %s", res, description)

	err = rows.Close()
	if err != nil {
		err = fmt.Errorf("while closing SQL record stream: %v, DB operation: %s", err, description)
		return nil, err
	}

	logrus.Debugf("successfully retrieved %d modifier codes, DB operation: %s", len(res), description)
	return res, nil
}

// BuildTimePoints runs the SQL queries, process their results to build sequential data and aggregate them.
func (db PostgresDatabase) BuildTimePoints(
	patientSetID int64,
	startConceptCodes []string,
	startModifierCodes []string,
	startEarliest bool,
	endConceptCodes []string,
	endModifierCodes []string,
	endEarliest bool,
	maxLimit int64,
) (
	eventAggregates map[int64]*Events,
	patientsWithStartEvent int64,
	patientsWithoutAnyEndEvent map[int64]struct{},
	err error,
) {
	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "BuildTimePoints")
	defer span.End()

	patientsToStartEvent, err := db.startEvent(patientSetID, startConceptCodes, startModifierCodes, startEarliest)
	if err != nil {
		return
	}
	patientsWithStartEvent = int64(len(patientsToStartEvent))

	patientsToEndEvents, err := db.endEvents(patientsToStartEvent, endConceptCodes, endModifierCodes)
	if err != nil {
		return
	}

	patientsWithoutEnd, startToEndEvent, err := db.patientAndEndEvents(patientsToStartEvent, patientsToEndEvents, endEarliest)
	if err != nil {
		return
	}

	patientsToCensoringEvent, patientsWithoutAnyEndEvent, err := db.censoringEvent(patientsToStartEvent, patientsWithoutEnd, endConceptCodes, endModifierCodes)
	if err != nil {
		return
	}

	startToCensoringEvent, err := db.patientAndCensoring(patientsToStartEvent, patientsWithoutEnd, patientsToCensoringEvent)
	if err != nil {
		return
	}

	eventAggregates, err = db.compileTimePoints(startToEndEvent, startToCensoringEvent, maxLimit)
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
func (db PostgresDatabase) patientAndEndEvents(startEvent map[int64]time.Time, endEvents map[int64][]time.Time, endEarliest bool) (map[int64]struct{}, map[int64]int64, error) {

	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "patientAndEvents")
	defer span.End()

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
func (db PostgresDatabase) patientAndCensoring(startEvent map[int64]time.Time, patientsWithoutEndEvent map[int64]struct{}, patientWithCensoring map[int64]time.Time) (map[int64]int64, error) {
	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "patientAndCensoring")
	defer span.End()

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
func (db PostgresDatabase) compileTimePoints(patientWithEndEvents, patientWithCensoringEvents map[int64]int64, maxLimit int64) (map[int64]*Events, error) {
	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "compileTimePoints")
	defer span.End()

	if maxLimit <= 0 {
		err := fmt.Errorf("user-defined maximum limit %d must be strictly greater than 0", maxLimit)
		return nil, err
	}
	timePointTable := make(map[int64]*Events, int(maxLimit))
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
			timePointTable[timePoint] = &Events{
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
			timePointTable[timePoint] = &Events{
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

// startEvent calls the postgres procedure to get the list of patients and start event. Concept codes and modifier codes define the start event.
// As multiple candidates are possible, earliest flag defines if the earliest or the latest date must be considered as the start event.
func (db PostgresDatabase) startEvent(patientSetID int64, conceptCodes, modifierCodes []string, earliest bool) (map[int64]time.Time, error) {

	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "startEvent")
	defer span.End()

	conceptDefinition := "{" + strings.Join(conceptCodes, ",") + "}"
	modifierDefinition := "{" + strings.Join(modifierCodes, ",") + "}"

	description := fmt.Sprintf("get start event (patient set ID: %d, start concept codes: %s, start modifier codes: %s, begins with earliest occurence: %t): procedure: %s",
		patientSetID, conceptDefinition, modifierDefinition, earliest, "i2b2demodata.start_event")

	logrus.Debugf("survival analysis: timepoints: retrieving the start event dates for the patients: %s", description)

	err := db.handle.Ping()
	if err != nil {
		err = fmt.Errorf("while connecting to database when calling start event: %v", err)
		return nil, err
	}
	row, err := db.handle.Query("SELECT i2b2demodata.start_event($1,$2,$3,$4)", patientSetID, conceptDefinition, modifierDefinition, earliest)
	if err != nil {
		err = fmt.Errorf("while calling database for retrieving start event dates: %s; DB operation: %s", err.Error(), description)
		return nil, err
	}

	patientsWithStartEvent := make(map[int64]time.Time)

	var record = new(string)
	for row.Next() {
		err = row.Scan(record)
		if err != nil {
			err = fmt.Errorf("while reading database record stream for retrieving start event dates: %s; DB operation: %s", err.Error(), description)
			return nil, err
		}

		recordEntries := strings.Split(strings.Trim(*record, "()"), ",")
		if len(recordEntries) != 2 {
			err = fmt.Errorf("while parsing SQL record stream: expected to find 2 items in a string like \"(<integer>,<date>)\" in record %s", *record)
			return nil, err
		}
		patientID, err := strconv.ParseInt(recordEntries[0], 10, 64)
		if err != nil {
			err = fmt.Errorf("while parsing patient number \"%s\": %s; DB operation: %s", recordEntries[0], err.Error(), description)
			return nil, err
		}
		startDate, err := time.Parse(dateFormat, recordEntries[1])
		if err != nil {
			err = fmt.Errorf("while parsing patient number \"%s\": %s; DB operation: %s", recordEntries[1], err.Error(), description)
			return nil, err
		}

		if _, isIn := patientsWithStartEvent[patientID]; isIn {
			err = fmt.Errorf("while filling patient-to-start-date map: patient %d already found in map, this is not expected; DB operation: %s", patientID, description)
			return nil, err
		}

		patientsWithStartEvent[patientID] = startDate

	}

	logrus.Debugf("Survival analysis: timepoints: successfully found %d patients with start event; DB operation: %s", len(patientsWithStartEvent), description)
	return patientsWithStartEvent, nil

}

// endEvents calls the postgres procedure to get the list of patients and end events. Concept codes and modifier codes define the end event.
// As multiple candidates are possible, the list of potential end events strictly happening after the start event is stored in the return map.
func (db PostgresDatabase) endEvents(patientWithStartEventList map[int64]time.Time, conceptCodes, modifierCodes []string) (map[int64][]time.Time, error) {
	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "endEvents")
	defer span.End()

	setStrings := make([]string, 0, len(patientWithStartEventList))

	for patient := range patientWithStartEventList {
		setStrings = append(setStrings, strconv.FormatInt(patient, 10))
	}
	setDefinition := "{" + strings.Join(setStrings, ",") + "}"
	conceptDefinition := "{" + strings.Join(conceptCodes, ",") + "}"
	modifierDefinition := "{" + strings.Join(modifierCodes, ",") + "}"

	description := fmt.Sprintf("get start event (patient list: %s, end concept codes: %s, end modifier codes: %s): procedure: %s",
		setDefinition, conceptDefinition, modifierDefinition, "i2b2demodata.end_events")

	logrus.Debugf("survival analysis: timepoints: retrieving the end event dates for the patients: %s", description)
	err := db.handle.Ping()
	if err != nil {
		err = fmt.Errorf("while connecting to database when calling start event: %v", err)
		return nil, err
	}
	row, err := db.handle.Query("SELECT i2b2demodata.end_events($1,$2,$3)", setDefinition, conceptDefinition, modifierDefinition)
	if err != nil {
		err = fmt.Errorf("while calling database for retrieving end event dates: %v; DB operation: %s", err, description)
		return nil, err
	}

	patientsWithEndEvent := make(map[int64][]time.Time, len(patientWithStartEventList))

	var record = new(string)
	for row.Next() {
		err = row.Scan(record)
		if err != nil {
			err = fmt.Errorf("while reading database record stream for retrieving start event dates: %v; DB operation: %s", err, description)
			return nil, err
		}

		recordEntries := strings.Split(strings.Trim(*record, "()"), ",")
		if len(recordEntries) != 2 {
			err = fmt.Errorf("while parsing SQL record stream: expected to find 2 items in a string like \"(<integer>,<date>)\" in record %s", *record)
			return nil, err
		}
		patientID, err := strconv.ParseInt(recordEntries[0], 10, 64)
		if err != nil {
			err = fmt.Errorf("while parsing patient number \"%s\": %v; DB operation: %s", recordEntries[0], err, description)
			return nil, err
		}
		endDate, err := time.Parse(dateFormat, recordEntries[1])
		if err != nil {
			err = fmt.Errorf("while parsing end date \"%s\": %v; DB operation: %s", recordEntries[1], err, description)
			return nil, err
		}

		if patientWithStartEventList[patientID].Before(endDate) {

			// here, an aggregate was not performed, so it is expected to find a patient ID more than once

			if _, isIn := patientsWithEndEvent[patientID]; isIn {
				patientsWithEndEvent[patientID] = append(patientsWithEndEvent[patientID], endDate)
			} else {
				patientsWithEndEvent[patientID] = []time.Time{endDate}
			}
		} else {
			logrus.Tracef("dropped end date: end date %s before start date %s; patientID: %d", endDate.Format(dateFormat), patientWithStartEventList[patientID].Format(dateFormat), patientID)
		}

	}
	logrus.Debugf("survival analysis: timepoints: successfully found %d patients with end event; DB operation: %s", len(patientsWithEndEvent), description)
	return patientsWithEndEvent, nil

}

// censoringEvent calls the postgres procedure to get the list of patients and censoring event. All observations whose concept or modifier code are different from those provided are potential censoring events.
// The event with the latest end date should be considered (for each observation, if the end date is missing, the start date should be taken instead).
// If the start event does not occur before the end event, the event is dropped and the patient is inserted in the set of patient-without-censoring-events (they should miss both event of interest and censoring event).
func (db PostgresDatabase) censoringEvent(patientWithStartEventList map[int64]time.Time, patientWithoutEndEvent map[int64]struct{}, endConceptCodes []string, endModifierCodes []string) (map[int64]time.Time, map[int64]struct{}, error) {
	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "censoringEvent")
	defer span.End()

	setStrings := make([]string, 0, len(patientWithoutEndEvent))

	for patient := range patientWithoutEndEvent {
		setStrings = append(setStrings, strconv.FormatInt(patient, 10))
	}
	setDefinition := "{" + strings.Join(setStrings, ",") + "}"
	conceptDefinition := "{" + strings.Join(endConceptCodes, ",") + "}"
	modifierDefinition := "{" + strings.Join(endModifierCodes, ",") + "}"

	description := fmt.Sprintf("get start event (patient list: %s, start concept codes: %s, start modifier codes: %s): procedure: %s",
		setDefinition, conceptDefinition, modifierDefinition, "i2b2demodata.censoring_event")

	logrus.Debugf("survival analysis: timepoints: retrieving the censoring event dates for the patients: %s", description)
	err := db.handle.Ping()
	if err != nil {
		err = fmt.Errorf("while connecting to database when calling start event: %v", err)
		return nil, nil, err
	}
	row, err := db.handle.Query("SELECT i2b2demodata.censoring_event($1,$2,$3)", setDefinition, conceptDefinition, modifierDefinition)
	if err != nil {
		err = fmt.Errorf("while calling database for retrieving right censoring event dates: %s; DB operation: %s", err.Error(), description)
		return nil, nil, err
	}

	patientsWithCensoringEvent := make(map[int64]time.Time, len(patientWithoutEndEvent))
	patientsWithoutCensoringEvent := make(map[int64]struct{}, len(patientWithoutEndEvent))

	var record = new(string)
	for row.Next() {
		err = row.Scan(record)
		if err != nil {
			err = fmt.Errorf("while reading database record stream for retrieving start event dates: %v; DB operation: %s", err, description)
			return nil, nil, err
		}

		recordEntries := strings.Split(strings.Trim(*record, "()"), ",")
		if len(recordEntries) != 2 {
			err = fmt.Errorf("while parsing SQL record stream: expected to find 2 items in a string like \"(<integer>,<date>)\" in record %s", *record)
			return nil, nil, err
		}
		patientID, err := strconv.ParseInt(recordEntries[0], 10, 64)
		if err != nil {
			err = fmt.Errorf("while parsing patient number \"%s\": %v; DB operation: %s", recordEntries[0], err, description)
			return nil, nil, err
		}
		censoringDate, err := time.Parse(dateFormat, recordEntries[1])
		if err != nil {
			err = fmt.Errorf("while parsing patient number \"%s\": %v; DB operation: %s", recordEntries[1], err, description)
			return nil, nil, err
		}

		if _, ok := patientWithStartEventList[patientID]; !ok {
			err = fmt.Errorf("while looking for a start date patient %d was not found in start event map, this is not expected; DB operation: %s", patientID, description)
			return nil, nil, err
		}

		if patientWithStartEventList[patientID].Before(censoringDate) {

			if _, isIn := patientsWithCensoringEvent[patientID]; isIn {
				err = fmt.Errorf("while filling patient-to-censoring-date map: patient %d already found in map, this is not expected; DB operation: %s", patientID, description)
				return nil, nil, err
			}

			patientsWithCensoringEvent[patientID] = censoringDate
		} else {
			if _, isIn := patientsWithoutCensoringEvent[patientID]; isIn {
				err = fmt.Errorf("while filling patient-without-censoring set: patient %d already found in set, this is not expected; DB operation: %s", patientID, description)
				return nil, nil, err
			}
			patientsWithoutCensoringEvent[patientID] = struct{}{}
		}

	}

	logrus.Debugf("survival analysis: timepoints: successfully found %d patients with right censoring event; DB operation: %s", len(patientsWithCensoringEvent), description)
	return patientsWithCensoringEvent, patientsWithoutCensoringEvent, nil
}

// getTableName gets the ontology table name for a given table code (in I2B2, the first node of a URI is the table CD).
// It returns an error when no entry was found for the provided table code.
func (db PostgresDatabase) getTableName(tableCD string) (string, error) {

	description := fmt.Sprintf("getTableName (table code: %s), procedure: %s", tableCD, "i2b2metadata.table_name")
	logrus.Debugf("querying the name of the ontology table for the code embedded in I2B2 item definition: %s", description)

	err := db.handle.Ping()
	if err != nil {
		err = fmt.Errorf("while connecting to database to get table name: %v", err)
		return "", err
	}
	row := db.handle.QueryRow("SELECT i2b2metadata.table_name($1);", tableCD)
	ret := new(string)
	err = row.Scan(ret)
	if err != nil {
		err = fmt.Errorf("while getting ontology table name: %v, DB operation: %s", err, description)
		logrus.Error(err)
		return "", err
	}
	logrus.Debugf(`successfully ontology table name "%s", DB operation: %s`, *ret, description)

	return strings.ToLower(*ret), nil
}

// extracts table name and URI
func extractTableAndURI(pathURI string) (tableName, pathWoTable string) {
	pathURI = strings.Trim(pathURI, "/")
	tokens := strings.Split(pathURI, "/")
	switch len(tokens) {
	case 0:
		return "", ""
	case 1:
		return tokens[0], ""
	default:
		return tokens[0], "/" + strings.Join(tokens[1:], "/")
	}
}

// prepareLike prepare path for LIKE operator
func prepareLike(pathURI string) string {
	path := strings.Replace(pathURI, "/", `\\`, -1)
	if strings.HasSuffix(path, "%") {
		return path
	}
	if strings.HasSuffix(path, `\\`) {
		return path + "%"
	}
	return path + `\\%`
}

// prepareEqual prepare path for LIKE operator
func prepareEqual(pathURI string) string {
	return strings.Replace(pathURI, "/", `\`, -1)
}
