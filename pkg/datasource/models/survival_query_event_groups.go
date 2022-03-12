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

// SortAndFlatten orders and flattens an EventGroups.
// Each event group is flattened as a vector of 1 + 2n elements, where n is the number of group's time points.
// The element at position 0 contains the initial count for the group, and each couple of following elements contains
// the aggregated number of events of interest and the aggregated number of censoring events for each time point in the group.
// All flattened event groups are concatenated in @flatEventGroups, whose size is then m(1 + 2n), where m is the number of event groups.
func (eventGroups EventGroups) SortAndFlatten() (flatEventGroups []int64, err error) {

	if len(eventGroups) == 0 {
		return nil, fmt.Errorf("no group")
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
		return nil, fmt.Errorf("all groups are empty")
	}

	sort.Sort(sortedEventGroups)

	// ---------  flattening
	flatEventGroups = make([]int64, 0)

	for _, group := range sortedEventGroups {
		flatEventGroups = append(flatEventGroups, group.InitialCount)
		for _, timePoint := range group.TimePointResults {
			flatEventGroups = append(flatEventGroups, timePoint.Result.EventValueAgg)
			flatEventGroups = append(flatEventGroups, timePoint.Result.CensoringValueAgg)
		}
	}

	logrus.Debugf("flat inputs: %v", flatEventGroups)

	return

}
