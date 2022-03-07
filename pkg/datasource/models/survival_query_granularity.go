package models

import (
	"math"
)

const (
	dInWeek  = 7
	dInMonth = 30
	dInYear  = 365
)

var granularityValues = map[string]int{
	"day":   1,
	"week":  dInWeek,
	"month": dInMonth,
	"year":  dInYear,
}

var granularityFunctions = map[string]func(int64) int64{
	"day":   func(x int64) int64 { return x },
	"week":  week,
	"month": month,
	"year":  year,
}

func ceil(val int, granularity int) int {
	return int(math.Ceil(float64(val) / float64(granularity)))
}

func week(val int64) int64 {
	return int64(ceil(int(val), dInWeek))
}

func month(val int64) int64 {
	return int64(ceil(int(val), dInMonth))
}

func year(val int64) int64 {
	return int64(ceil(int(val), dInYear))
}
