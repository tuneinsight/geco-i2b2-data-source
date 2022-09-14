package models

import (
	"fmt"
)

// TimePoint contains a relative time, the numbers of events of interest and censoring events occured at that time.
type TimePoint struct {
	Time   int64
	Events Events
}

// Events contains the number of events of interest and censoring events occurring at the same relative time.
type Events struct {
	EventsOfInterest int64
	CensoringEvents  int64
}

// TimePoints is a slice containing the time points and respective counts of censoring events and events of interest.
// TimePoints implements sort.Interface interface.
type TimePoints []TimePoint

// Len implements Len method for sort.Interface interface.
func (tps TimePoints) Len() int {
	return len(tps)
}

// Less implements Less method for sort.Interface interface
func (tps TimePoints) Less(i, j int) bool {
	return tps[i].Time < tps[j].Time
}

// Swap implements Swap method for sort.Interface interface.
func (tps TimePoints) Swap(i, j int) {
	tps[i], tps[j] = tps[j], tps[i]
}

// Bin bins the time points according to provided @granularity.
func (tps TimePoints) Bin(granularity string) (TimePoints, error) {
	if granFunction, isIn := granularityFunctions[granularity]; isIn {
		return tps.binTimePoint(granFunction), nil
	}
	return nil, fmt.Errorf("granularity %s is not implemented: should be one of year, month, week, day", granularity)

}

func (tps TimePoints) binTimePoint(groupingFunction func(int64) int64) TimePoints {
	bins := make(map[int64]struct {
		EventsOfInterest int64
		CensoringEvents  int64
	})
	var ceiled int64
	for _, tp := range tps {
		ceiled = groupingFunction(tp.Time)
		if val, isInside := bins[ceiled]; isInside {
			bins[ceiled] = struct {
				EventsOfInterest int64
				CensoringEvents  int64
			}{
				EventsOfInterest: val.EventsOfInterest + tp.Events.EventsOfInterest,
				CensoringEvents:  val.CensoringEvents + tp.Events.CensoringEvents,
			}
		} else {
			bins[ceiled] = struct {
				EventsOfInterest int64
				CensoringEvents  int64
			}{
				EventsOfInterest: tp.Events.EventsOfInterest,
				CensoringEvents:  tp.Events.CensoringEvents,
			}
		}
	}

	newSQLTimePoints := make(TimePoints, 0)
	for time, agg := range bins {
		newSQLTimePoints = append(newSQLTimePoints, TimePoint{
			Time: time,
			Events: struct {
				EventsOfInterest int64
				CensoringEvents  int64
			}{
				EventsOfInterest: agg.EventsOfInterest,
				CensoringEvents:  agg.CensoringEvents,
			},
		})
	}
	return newSQLTimePoints
}

// Expand adds zeros for events of interest and censoring events for each missing relative time from 0 to timeLimit.
// Relative times greater than @timeLimitDay (time unit: day) are discarded.
func (tps TimePoints) Expand(timeLimitDay int, granularity string) (TimePoints, error) {
	var timeLimit int64
	if granFunction, isIn := granularityFunctions[granularity]; isIn {
		timeLimit = granFunction(int64(timeLimitDay))
	} else {
		return nil, fmt.Errorf("granularity %s is not implemented", granularity)
	}

	res := make(TimePoints, timeLimit)
	availableTimePoints := make(map[int64]struct {
		EventsOfInterest int64
		CensoringEvents  int64
	}, len(tps))
	for _, timePoint := range tps {

		availableTimePoints[timePoint.Time] = timePoint.Events
	}
	for i := int64(0); i < timeLimit; i++ {
		if events, ok := availableTimePoints[i]; ok {
			res[i] = TimePoint{
				Time:   i,
				Events: events,
			}
		} else {
			res[i] = TimePoint{
				Time: i,
				Events: struct {
					EventsOfInterest int64
					CensoringEvents  int64
				}{
					EventsOfInterest: 0,
					CensoringEvents:  0,
				},
			}
		}

	}
	return res, nil
}
