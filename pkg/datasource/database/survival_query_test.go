package database

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestTimePointsMapFromTable(t *testing.T) {
	res := timePointsMapFromTable([][]int64{{1, 2, 3}, {4, 5, 6}})
	firstEvents, isIn := res[1]
	assert.True(t, isIn)
	assert.Equal(t, &Events{
		EventsOfInterest: 2,
		CensoringEvents:  3,
	}, firstEvents)
	secondEvents, isIn := res[4]
	assert.True(t, isIn)
	assert.Equal(t, &Events{
		EventsOfInterest: 5,
		CensoringEvents:  6,
	}, secondEvents)

}

func TestGetTableName(t *testing.T) {

	db := getDB(t)
	defer dbCleanUp(t, db)

	expected := "test"
	res, err := db.getTableName("SPHN")
	assert.NoError(t, err)
	assert.Equal(t, expected, res)

	_, err = db.getTableName("this table does not exist")
	assert.Error(t, err)
}

func TestGetConceptCodes(t *testing.T) {

	db := getDB(t)
	defer dbCleanUp(t, db)

	expectedList := []string{"TEST:1", "TEST:2", "TEST:3"}

	res, err := db.GetConceptCodes("/TEST/test/%")
	assert.NoError(t, err)
	assert.ElementsMatch(t, expectedList, res)

	res, err = db.GetConceptCodes("/TEST/test/")
	assert.NoError(t, err)
	assert.ElementsMatch(t, expectedList, res)

	res, err = db.GetConceptCodes("/TEST/test")
	assert.NoError(t, err)
	assert.ElementsMatch(t, expectedList, res)

}

func TestGetModifierCodes(t *testing.T) {

	db := getDB(t)
	defer dbCleanUp(t, db)

	expectedList1 := []string{"TEST:5", "TEST:4-1"}
	expectedList2 := []string{"TEST:5"}

	res, err := db.GetModifierCodes(`/TEST/modifiers1/%`, `/test/1/`)
	assert.NoError(t, err)
	assert.ElementsMatch(t, res, expectedList1)
	res, err = db.GetModifierCodes(`/TEST/modifiers1/1/`, `/test/1/`)
	assert.NoError(t, err)
	assert.ElementsMatch(t, res, expectedList2)

}

func TestStartEvent(t *testing.T) {

	db := getDB(t)
	defer dbCleanUp(t, db)

	patientSetID1 := int64(-201) // it contains no patients
	patientSetID2 := int64(-301) // it contains 1137,1138
	patientSetID3 := int64(-401) // it contains 1137,1138,9999999

	// test empty, it should not throw an error
	emptyResult, err := db.startEvent(patientSetID1, []string{"A168", "A125"}, []string{"@"}, true)
	assert.NoError(t, err)
	assert.Empty(t, emptyResult)

	emptyResult, err = db.startEvent(patientSetID2, []string{}, []string{"@"}, true)
	assert.NoError(t, err)
	assert.Empty(t, emptyResult)

	emptyResult, err = db.startEvent(patientSetID2, []string{"A168", "A125"}, []string{}, true)
	assert.NoError(t, err)
	assert.Empty(t, emptyResult)

	// test with correct parameters, and an extra patient
	result, err := db.startEvent(patientSetID3, []string{"A168", "A125"}, []string{"@"}, true)
	assert.NoError(t, err)
	expectedFirstTime, err := time.Parse(dateFormat, "1971-04-15")
	assert.NoError(t, err)
	expectedSecondTime, err := time.Parse(dateFormat, "1970-03-14")
	assert.NoError(t, err)
	assert.Equal(t, 2, len(result))

	firstTime, isIn := result[1137]
	assert.True(t, isIn)
	assert.Equal(t, expectedFirstTime, firstTime)

	secondTime, isIn := result[1138]
	assert.True(t, isIn)
	assert.Equal(t, expectedSecondTime, secondTime)

	// another test with latest instead of earliest
	result, err = db.startEvent(patientSetID2, []string{"A168", "A125"}, []string{"@"}, false)
	assert.NoError(t, err)
	expectedFirstTime, err = time.Parse(dateFormat, "1972-02-15")
	assert.NoError(t, err)
	expectedSecondTime, err = time.Parse(dateFormat, "1971-06-12")
	assert.NoError(t, err)

	firstTime, isIn = result[1137]
	assert.True(t, isIn)
	assert.Equal(t, expectedFirstTime, firstTime)

	secondTime, isIn = result[1138]
	assert.True(t, isIn)
	assert.Equal(t, expectedSecondTime, secondTime)

}

func TestEndEvents(t *testing.T) {

	db := getDB(t)
	defer dbCleanUp(t, db)

	absoluteEarliest, err := time.Parse(dateFormat, "1970-03-13")
	assert.NoError(t, err)

	fullStartEventMap := map[int64]time.Time{
		1137: absoluteEarliest,
		1138: absoluteEarliest,
	}

	// test empty, it should not throw an error
	emptyResult, err := db.endEvents(map[int64]time.Time{}, []string{"A168", "A125"}, []string{"@"})
	assert.NoError(t, err)
	assert.Empty(t, emptyResult)

	emptyResult, err = db.endEvents(fullStartEventMap, []string{}, []string{"@"})
	assert.NoError(t, err)
	assert.Empty(t, emptyResult)

	emptyResult, err = db.endEvents(fullStartEventMap, []string{"A168", "A125"}, []string{})
	assert.NoError(t, err)
	assert.Empty(t, emptyResult)

	// expect all results
	result, err := db.endEvents(fullStartEventMap, []string{"A168", "A125"}, []string{"@"})
	assert.NoError(t, err)

	expectedFirstList := createDateListFromString(t, []string{"1971-04-15", "1972-02-15"})

	firstList, isIn := result[1137]
	assert.True(t, isIn)
	assert.ElementsMatch(t, expectedFirstList, firstList)

	expectedSecondList := createDateListFromString(t, []string{"1970-03-14", "1971-06-12"})

	secondList, isIn := result[1138]
	assert.True(t, isIn)
	assert.ElementsMatch(t, expectedSecondList, secondList)

	// expect shorter list if the start date is equal or bigger
	collidingEarliest, err := time.Parse(dateFormat, "1970-03-14")
	assert.NoError(t, err)

	oneCollisionStartEventMap := map[int64]time.Time{
		1137: collidingEarliest,
		1138: collidingEarliest,
	}
	result, err = db.endEvents(oneCollisionStartEventMap, []string{"A168", "A125"}, []string{"@"})
	assert.NoError(t, err)

	expectedList := createDateListFromString(t, []string{"1971-06-12"})

	list, isIn := result[1138]
	assert.True(t, isIn)
	assert.ElementsMatch(t, expectedList, list)

	// expect empty results
	latest, err := time.Parse(dateFormat, "1972-02-15")
	assert.NoError(t, err)

	latestStartEventMap := map[int64]time.Time{
		1137: latest,
		1138: latest,
	}
	result, err = db.endEvents(latestStartEventMap, []string{"A168", "A125"}, []string{"@"})
	assert.NoError(t, err)

	_, isIn = result[1138]
	assert.False(t, isIn)

}

func TestCensoringEvent(t *testing.T) {

	db := getDB(t)
	defer dbCleanUp(t, db)

	absoluteEarliest, err := time.Parse(dateFormat, "1970-03-13")
	assert.NoError(t, err)

	fullStartEventMap := map[int64]time.Time{
		1137: absoluteEarliest,
		1138: absoluteEarliest,
	}

	patientsNoEndEvent := map[int64]struct{}{
		1137: {},
		1138: {},
	}

	// the second argument is a subset of the first argument, an error is expected
	emptyResult, patientWithoutCensoring, err := db.censoringEvent(map[int64]time.Time{}, patientsNoEndEvent, []string{"A168", "A125"}, []string{"@"})
	assert.Empty(t, emptyResult)
	assert.Empty(t, patientWithoutCensoring)
	assert.Error(t, err)

	emptyResult, patientWithoutCensoring, err = db.censoringEvent(fullStartEventMap, map[int64]struct{}{}, []string{"A168", "A125"}, []string{"@"})
	assert.NoError(t, err)
	assert.Empty(t, emptyResult)
	assert.Empty(t, patientWithoutCensoring)

	timeStrings := createDateListFromString(t, []string{"1972-02-15", "1971-06-12"})
	expectedCensoring := map[int64]time.Time{
		1137: timeStrings[0],
		1138: timeStrings[1],
	}

	expectedCensoringAuxiliary := func(t *testing.T, patientWithoutCensoring map[int64]struct{}, results map[int64]time.Time) {
		assert.NoError(t, err)
		assert.Empty(t, patientWithoutCensoring)
		firstTime, isIn := results[1137]
		assert.True(t, isIn)
		assert.Equal(t, expectedCensoring[1137], firstTime)
		secondTime, isIn := results[1138]
		assert.True(t, isIn)
		assert.Equal(t, expectedCensoring[1138], secondTime)
	}

	results, patientWithoutCensoring, err := db.censoringEvent(fullStartEventMap, patientsNoEndEvent, []string{}, []string{"@"})
	expectedCensoringAuxiliary(t, patientWithoutCensoring, results)

	results, patientWithoutCensoring, err = db.censoringEvent(fullStartEventMap, patientsNoEndEvent, []string{"A168", "A125"}, []string{})
	expectedCensoringAuxiliary(t, patientWithoutCensoring, results)

	results, patientWithoutCensoring, err = db.censoringEvent(fullStartEventMap, patientsNoEndEvent, []string{"A168", "A125"}, []string{"@"})
	expectedCensoringAuxiliary(t, patientWithoutCensoring, results)

	// put all possible concept and modifier codes, expecting empty results, but no error
	emptyResult, patientWithoutCensoring, err = db.censoringEvent(fullStartEventMap, patientsNoEndEvent, []string{"A168", "A125", "DEM|SEX:f"}, []string{"@", "126:1", "171:0"})
	assert.NoError(t, err)
	assert.Empty(t, emptyResult)
	assert.Empty(t, patientWithoutCensoring)

	// put start events that do not occur before any other events
	absoluteLatest, err := time.Parse(dateFormat, "1972-02-15")
	assert.NoError(t, err)

	lateStartEventMap := map[int64]time.Time{
		1137: absoluteLatest,
		1138: absoluteLatest,
	}

	emptyResult, patientWithoutCensoring, err = db.censoringEvent(lateStartEventMap, patientsNoEndEvent, []string{}, []string{})
	assert.NoError(t, err)
	assert.Empty(t, emptyResult)
	_, isIn := patientWithoutCensoring[1137]
	assert.True(t, isIn)
	_, isIn = patientWithoutCensoring[1138]
	assert.True(t, isIn)

}

func TestPatientAndEndEvents(t *testing.T) {

	db := getDB(t)
	defer dbCleanUp(t, db)

	someDates := createDateListFromString(t, []string{
		"1970-09-01",
		"1970-09-02",
		"1970-09-03",
		"1970-09-04",
		"1970-09-05",
		"1970-09-06",
		"1970-09-07"})

	// test earliest
	withoutEndEvents, relativeTime, err := db.patientAndEndEvents(map[int64]time.Time{
		0: someDates[0],
		1: someDates[1],
	}, map[int64][]time.Time{
		0: {someDates[2], someDates[3]},
		1: {someDates[4], someDates[5]},
	},
		true,
	)

	assert.NoError(t, err)
	assert.Empty(t, withoutEndEvents)
	count1, isIn := relativeTime[0]
	assert.True(t, isIn)
	assert.Equal(t, int64(2), count1)
	count2, isIn := relativeTime[1]
	assert.True(t, isIn)
	assert.Equal(t, int64(3), count2)

	// test latest
	withoutEndEvents, relativeTime, err = db.patientAndEndEvents(map[int64]time.Time{
		0: someDates[0],
		1: someDates[1],
	}, map[int64][]time.Time{
		0: {someDates[2], someDates[3]},
		1: {someDates[4], someDates[5]},
	},
		false,
	)

	assert.NoError(t, err)
	assert.Empty(t, withoutEndEvents)
	count1, isIn = relativeTime[0]
	assert.True(t, isIn)
	assert.Equal(t, int64(3), count1)
	count2, isIn = relativeTime[1]
	assert.True(t, isIn)
	assert.Equal(t, int64(4), count2)

	// test patient without end events
	withoutEndEvents, relativeTime, err = db.patientAndEndEvents(map[int64]time.Time{
		0: someDates[0],
		1: someDates[1],
	}, map[int64][]time.Time{
		0: {someDates[3]},
	},
		false,
	)

	assert.NoError(t, err)
	_, isIn = withoutEndEvents[1]
	assert.True(t, isIn)
	count1, isIn = relativeTime[0]
	assert.True(t, isIn)
	assert.Equal(t, int64(3), count1)
	_, isIn = relativeTime[1]
	assert.False(t, isIn)

	// test wrong data, end event occurring after
	_, _, err = db.patientAndEndEvents(map[int64]time.Time{
		0: someDates[6],
	}, map[int64][]time.Time{
		0: {someDates[0]},
	},
		false,
	)

	assert.Error(t, err)

	// test wrong data, end event is the same

	_, _, err = db.patientAndEndEvents(map[int64]time.Time{
		0: someDates[0],
	}, map[int64][]time.Time{
		0: {someDates[0]},
	},
		false,
	)

	assert.Error(t, err)

	// test wrong data, empty list
	_, _, err = db.patientAndEndEvents(map[int64]time.Time{
		0: someDates[0],
	}, map[int64][]time.Time{
		0: {},
	},
		false,
	)

	assert.Error(t, err)

	// test wrong data, nil
	_, _, err = db.patientAndEndEvents(map[int64]time.Time{
		0: someDates[0],
	}, map[int64][]time.Time{
		0: nil,
	},
		false,
	)

	assert.Error(t, err)

}

func TestPatientAndCensoring(t *testing.T) {
	db := getDB(t)
	defer dbCleanUp(t, db)

	someDates := (createDateListFromString(t, []string{
		"1970-09-01",
		"1970-09-02",
		"1970-09-03",
		"1970-09-04",
		"1970-09-05",
		"1970-09-06",
		"1970-09-07"}))

	// test full set, the extra data in end events is silently ignored

	relativeTime, err := db.patientAndCensoring(map[int64]time.Time{
		0: someDates[0],
		1: someDates[1],
	},
		map[int64]struct{}{
			0: {},
			1: {},
		},
		map[int64]time.Time{
			0: someDates[2],
			1: someDates[4],
			2: someDates[5],
		},
	)
	assert.NoError(t, err)

	count1, isIn := relativeTime[0]
	assert.True(t, isIn)
	assert.Equal(t, int64(2), count1)
	count2, isIn := relativeTime[1]
	assert.True(t, isIn)
	assert.Equal(t, int64(3), count2)
	_, isIn = relativeTime[2]
	assert.False(t, isIn)

	// test one patient missing

	relativeTime, err = db.patientAndCensoring(map[int64]time.Time{
		0: someDates[0],
		1: someDates[1],
	},
		map[int64]struct{}{
			0: {},
		},
		map[int64]time.Time{
			0: someDates[2],
		},
	)
	assert.NoError(t, err)

	count1, isIn = relativeTime[0]
	assert.True(t, isIn)
	assert.Equal(t, int64(2), count1)
	_, isIn = relativeTime[1]
	assert.False(t, isIn)

	// test wrong data, extra data in patients-without-end-data

	_, err = db.patientAndCensoring(map[int64]time.Time{
		0: someDates[0],
	},
		map[int64]struct{}{
			0: {},
			1: {},
		},
		map[int64]time.Time{
			0: someDates[2],
			1: someDates[2],
		},
	)
	assert.Error(t, err)

	// test wrong data, censoring date before

	_, err = db.patientAndCensoring(map[int64]time.Time{
		0: someDates[4],
	},
		map[int64]struct{}{
			0: {},
		},
		map[int64]time.Time{
			0: someDates[0],
		},
	)
	assert.Error(t, err)

	// test wrong data, censoring same date

	_, err = db.patientAndCensoring(map[int64]time.Time{
		0: someDates[0],
	},
		map[int64]struct{}{
			0: {},
		},
		map[int64]time.Time{
			0: someDates[0],
		},
	)
	assert.Error(t, err)

}

func TestCompileTimePoints(t *testing.T) {
	db := getDB(t)
	defer dbCleanUp(t, db)

	patientsWithEndEvent := map[int64]int64{
		0: 1,
		1: 1,
		2: 3,
		3: 4,
	}

	patientsWithCensoring := map[int64]int64{
		4: 1,
		5: 2,
		6: 3,
		7: 3,
		8: 2,
	}
	expectedEvents := map[int64]*Events{
		1: {
			EventsOfInterest: 2,
			CensoringEvents:  1,
		},
		2: {
			EventsOfInterest: 0,
			CensoringEvents:  2,
		},
		3: {
			EventsOfInterest: 1,
			CensoringEvents:  2,
		},
		4: {
			EventsOfInterest: 1,
			CensoringEvents:  0,
		},
	}

	// test full events
	events, err := db.compileTimePoints(patientsWithEndEvent, patientsWithCensoring, int64(4))
	assert.NoError(t, err)

	for relativeTime, expectedEvent := range expectedEvents {
		event, isIn := events[relativeTime]
		assert.True(t, isIn, "event aggregates for relative time %d not found", relativeTime)

		assert.Equal(t, expectedEvent, event, "event aggregates for relative time %d are not the same as expected ones", relativeTime)
	}

	// test limit parameter
	expectedEventsLimited := make(map[int64]*Events, 3)
	for key, value := range expectedEvents {
		if key != 4 {
			expectedEventsLimited[key] = value
		}
	}

	events, err = db.compileTimePoints(patientsWithEndEvent, patientsWithCensoring, int64(3))
	assert.NoError(t, err)
	_, isIn := events[4]
	assert.False(t, isIn)

	for relativeTime, expectedEvent := range expectedEventsLimited {
		event, isIn := events[relativeTime]
		assert.True(t, isIn, "event aggregates for relative time %d not found", relativeTime)

		assert.Equal(t, expectedEvent, event, "event aggregates for relative time %d are not the same as expected ones", relativeTime)
	}

	// test wrong data, bad relative time
	_, err = db.compileTimePoints(map[int64]int64{0: 1, 1: 0}, patientsWithCensoring, int64(4))
	assert.Error(t, err)
	_, err = db.compileTimePoints(patientsWithEndEvent, map[int64]int64{6: 1, 7: 0}, int64(4))
	assert.Error(t, err)

	// test wrong data, bad time limit
	_, err = db.compileTimePoints(patientsWithEndEvent, patientsWithCensoring, int64(0))
	assert.Error(t, err)

}

func TestBuildTimePoints(t *testing.T) {

	db := getDB(t)
	defer dbCleanUp(t, db)

	patientSetID := int64(-101) // ID of the patient set of the test data
	patientCount := int64(228)

	var bigTimePoints = timePointsMapFromTable([][]int64{{5, 1, 0}, {11, 3, 0}, {12, 1, 0}, {13, 2, 0}, {15, 1, 0}, {26, 1, 0}, {30, 1, 0}, {31, 1, 0}, {53, 2, 0}, {54, 1, 0}, {59, 1, 0}, {60, 2, 0}, {61, 1, 0}, {62, 1, 0}, {65, 2, 0}, {71, 1, 0}, {79, 1, 0}, {81, 2, 0}, {88, 2, 0}, {92, 1, 1}, {93, 1, 0}, {95, 2, 0}, {105, 1, 1}, {107, 2, 0}, {110, 1, 0}, {116, 1, 0}, {118, 1, 0}, {122, 1, 0}, {131, 1, 0}, {132, 2, 0}, {135, 1, 0}, {142, 1, 0}, {144, 1, 0}, {145, 2, 0}, {147, 1, 0}, {153, 1, 0}, {156, 2, 0}, {163, 3, 0}, {166, 2, 0}, {167, 1, 0}, {170, 1, 0}, {173, 0, 1}, {174, 0, 1}, {175, 1, 1}, {176, 1, 0}, {177, 1, 1}, {179, 2, 0}, {180, 1, 0}, {181, 2, 0}, {182, 1, 0}, {183, 1, 0}, {185, 0, 1}, {186, 1, 0}, {188, 0, 1}, {189, 1, 0}, {191, 0, 1}, {192, 0, 1}, {194, 1, 0}, {196, 0, 1}, {197, 1, 1}, {199, 1, 0}, {201, 2, 0}, {202, 1, 1}, {203, 0, 1}, {207, 1, 0}, {208, 1, 0}, {210, 1, 0}, {211, 0, 1}, {212, 1, 0}, {218, 1, 0}, {221, 0, 1}, {222, 1, 1}, {223, 1, 0}, {224, 0, 1}, {225, 0, 2}, {226, 1, 0}, {229, 1, 0}, {230, 1, 0}, {235, 0, 1}, {237, 0, 1}, {239, 2, 0}, {240, 0, 1}, {243, 0, 1}, {245, 1, 0}, {246, 1, 0}, {252, 0, 1}, {259, 0, 1}, {266, 0, 1}, {267, 1, 0}, {268, 1, 0}, {269, 1, 1}, {270, 1, 0}, {272, 0, 1}, {276, 0, 1}, {279, 0, 1}, {283, 1, 0}, {284, 1, 1}, {285, 2, 0}, {286, 1, 0}, {288, 1, 0}, {291, 1, 0}, {292, 0, 2}, {293, 1, 0}, {296, 0, 1}, {300, 0, 1}, {301, 1, 1}, {303, 1, 1}, {305, 1, 0}, {306, 1, 0}, {310, 2, 0}, {315, 0, 1}, {320, 1, 0}, {329, 1, 0}, {332, 0, 1}, {337, 1, 0}, {340, 1, 0}, {345, 1, 0}, {348, 1, 0}, {350, 1, 0}, {351, 1, 0}, {353, 2, 0}, {356, 0, 1}, {361, 1, 0}, {363, 2, 0}, {364, 1, 1}, {371, 2, 0}, {376, 0, 1}, {382, 0, 1}, {384, 0, 1}, {387, 1, 0}, {390, 1, 0}, {394, 1, 0}, {404, 0, 1}, {413, 0, 1}, {426, 1, 0}, {428, 1, 0}, {429, 1, 0}, {433, 1, 0}, {442, 1, 0}, {444, 1, 1}, {450, 1, 0}, {455, 1, 0}, {457, 1, 0}, {458, 0, 1}, {460, 1, 0}, {473, 1, 0}, {477, 1, 0}, {511, 0, 2}, {519, 1, 0}, {520, 1, 0}, {524, 2, 0}, {529, 0, 1}, {533, 1, 0}, {543, 0, 1}, {550, 1, 0}, {551, 0, 1}, {558, 1, 0}, {559, 0, 1}, {567, 1, 0}, {574, 1, 0}, {583, 1, 0}, {588, 0, 1}, {613, 1, 0}, {624, 1, 0}, {641, 1, 0}, {643, 1, 0}, {654, 1, 0}, {655, 1, 0}, {687, 1, 0}, {689, 1, 0}, {705, 1, 0}, {707, 1, 0}, {728, 1, 0}, {731, 1, 0}, {735, 1, 0}, {740, 0, 1}, {765, 1, 0}, {791, 1, 0}, {806, 0, 1}, {814, 1, 0}, {821, 0, 1}, {840, 0, 1}, {883, 1, 0}, {965, 0, 1}, {1010, 0, 1}, {1022, 0, 1}})

	eventAggregates, patientsWithStartEvent, patientsWithoutEndEvent, err := db.BuildTimePoints(patientSetID, []string{"A168"}, []string{"@"}, true, []string{"A125"}, []string{"126:1"}, true, 2000)
	assert.NoError(t, err)
	assert.Empty(t, patientCount-patientsWithStartEvent)
	assert.Empty(t, patientsWithoutEndEvent)
	assert.Equal(t, len(bigTimePoints), len(eventAggregates), eventAggregates)
	for expectedTime, expectedEvent := range bigTimePoints {
		actualEvents, isIn := eventAggregates[expectedTime]
		assert.True(t, isIn)
		assert.Equal(t, expectedEvent, actualEvents, "for time %d", expectedTime)
	}

	// reverting arguments, should not throw an error
	eventAggregates, patientsWithStartEvent, patientsWithoutEndEvent, err = db.BuildTimePoints(patientSetID, []string{"A125"}, []string{"126:1"}, true, []string{"A168"}, []string{"@"}, true, 2000)
	assert.NoError(t, err)
	assert.NotEmpty(t, patientCount-patientsWithStartEvent)
	assert.NotEmpty(t, patientsWithoutEndEvent)
	assert.Empty(t, eventAggregates)

}

func timePointsMapFromTable(table [][]int64) map[int64]*Events {
	res := make(map[int64]*Events, len(table))
	for _, elm := range table {
		res[elm[0]] = &Events{
			EventsOfInterest: elm[1],
			CensoringEvents:  elm[2],
		}
	}
	return res
}

// createDateListFromString parses a list of times and returns the date.
func createDateListFromString(t *testing.T, dateStrings []string) (timeList []time.Time) {
	timeList = make([]time.Time, len(dateStrings))

	for i, dateString := range dateStrings {
		date, parseErr := time.Parse(dateFormat, dateString)
		assert.NoError(t, parseErr)
		timeList[i] = date
	}
	return
}
