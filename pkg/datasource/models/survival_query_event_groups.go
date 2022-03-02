package models

import (
	"fmt"
	"sort"

	"github.com/sirupsen/logrus"
)

// Result holds information about time point, events, execution times and error
type Result struct {
	EventValueAgg     int64
	CensoringValueAgg int64
}

// TimePointResult holds information about time point, events, execution times and error
type TimePointResult struct {
	TimePoint int64
	Result    Result
}

// String implements the Stringer interface.
func (t *TimePointResult) String() string {
	return fmt.Sprintf("{%d,%v}", t.TimePoint, t.Result)
}

// EventGroup holds the group name, the encryption of the initial group size and the list of encrypted time points.
type EventGroup struct {
	GroupID          string
	InitialCount     int64
	TimePointResults []*TimePointResult
}

// String implements the Stringer interface.
func (eventGroup *EventGroup) String() string {
	return fmt.Sprintf("{%s,%d,%v}", eventGroup.GroupID, eventGroup.InitialCount, eventGroup.TimePointResults)
}

// EventGroups holds a list of EventGroup instances.
type EventGroups []*EventGroup

// Len returns the number of event groups.
func (eventGroups EventGroups) Len() int {
	return len(eventGroups)
}

// Less returns true if the event group at position i has a smaller ID than the event group at position j.
func (eventGroups EventGroups) Less(i, j int) bool {
	return eventGroups[i].GroupID < eventGroups[j].GroupID
}

// Swap swaps the event groups at positions i and j.
func (eventGroups EventGroups) Swap(i, j int) {
	eventGroups[i], eventGroups[j] = eventGroups[j], eventGroups[i]
}

// Len returns the number of time point results.
func (eventGroup EventGroup) Len() int {
	return len(eventGroup.TimePointResults)
}

// Less returns true if the time point at position i is smaller than the time point at position j.
func (eventGroup EventGroup) Less(i, j int) bool {
	return eventGroup.TimePointResults[i].TimePoint < eventGroup.TimePointResults[j].TimePoint
}

// Swap swaps the time point results at positions i and j.
func (eventGroup EventGroup) Swap(i, j int) {
	eventGroup.TimePointResults[i], eventGroup.TimePointResults[j] = eventGroup.TimePointResults[j], eventGroup.TimePointResults[i]
}

// SortAndFlatten orders and flattens and EventGroups.
func (eventGroups EventGroups) SortAndFlatten() (initialCounts, eventValuesAgg, censoringValuesAgg []int64, err error) {

	if len(eventGroups) == 0 {
		return nil, nil, nil, fmt.Errorf("no group")
	}

	var cumulativeLength int

	//-------- deep copy and sorting by keys
	sortedEventGroups := EventGroups{}

	for _, group := range eventGroups {
		timePointResults := make([]*TimePointResult, 0)

		for _, res := range group.TimePointResults {

			cumulativeLength++
			timePointResults = append(timePointResults, &TimePointResult{
				TimePoint: res.TimePoint,
				Result:    res.Result,
			})
		}
		eventGroup := &EventGroup{InitialCount: group.InitialCount, GroupID: group.GroupID, TimePointResults: timePointResults}

		sort.Sort(eventGroup)

		sortedEventGroups = append(sortedEventGroups, eventGroup)
	}

	if cumulativeLength == 0 {
		return nil, nil, nil, fmt.Errorf("all groups are empty")
	}

	sort.Sort(sortedEventGroups)

	// ---------  flattening
	initialCounts = make([]int64, 0)
	eventValuesAgg = make([]int64, 0)
	censoringValuesAgg = make([]int64, 0)
	for _, group := range sortedEventGroups {
		initialCounts = append(initialCounts, group.InitialCount)
		for _, timePoint := range group.TimePointResults {
			eventValuesAgg = append(eventValuesAgg, timePoint.Result.EventValueAgg)
			censoringValuesAgg = append(censoringValuesAgg, timePoint.Result.CensoringValueAgg)
		}
	}

	logrus.Debugf("initial counts: %v, event values agg: %v, censoring values agg: %v", initialCounts, eventValuesAgg, censoringValuesAgg)

	return

}
