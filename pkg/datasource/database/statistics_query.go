package database

import (
	"database/sql"
	"fmt"
	"strconv"
	"strings"

	"github.com/sirupsen/logrus"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk/telemetry"
)

// StatsObservation contains a patient observation.
type StatsObservation struct {
	NumericValue  float64
	Unit          string
	PatientNumber int64
}

// RetrieveObservationsForConcept returns the numerical values that correspond to the concept passed as argument for the specified cohort.
func (db PostgresDatabase) RetrieveObservationsForConcept(code string, patientIDs []int64, minObservations int64) (statsObservations []StatsObservation, err error) {
	logrus.Debugf("executing stats SQL query: %s, concept: %s, patients: %v", sqlConcept, code, patientIDs)

	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "RetrieveObservationsForConcept")
	defer span.End()

	return db.retrieveObservations(sqlConcept, code, patientIDs, minObservations)
}

// RetrieveObservationsForModifier returns the numerical values that correspond to the modifier passed as argument for the specified cohort.
func (db PostgresDatabase) RetrieveObservationsForModifier(code string, patientIDs []int64, minObservations int64) (statsObservations []StatsObservation, err error) {
	logrus.Debugf("executing stats SQL query: %s, modifier: %s, patients: %v", sqlModifier, code, patientIDs)

	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "RetrieveObservationsForModifier")
	defer span.End()

	return db.retrieveObservations(sqlModifier, code, patientIDs, minObservations)
}

// retrieveObservations returns the numerical values that correspond to the concept or modifier whose code is passed as argument for the specified cohort.
func (db PostgresDatabase) retrieveObservations(sqlQuery, code string, patientIDs []int64, minObservations int64) (statsObservations []StatsObservation, err error) {

	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "retrieveObservations")
	defer span.End()

	strPatientList := convertIntListToString(patientIDs)

	var rows *sql.Rows
	completeSQLQuery := sqlQuery + " " + sqlCohortFilter
	rows, err = db.handle.Query(completeSQLQuery, code, minObservations, strPatientList)

	if err != nil {
		err = fmt.Errorf("while execution SQL query: %s", err.Error())
		return
	}

	statsObservations = make([]StatsObservation, 0)

	for rows.Next() {
		numericValue := new(string)
		patientNb := new(string)
		unit := new(string)
		scanErr := rows.Scan(numericValue, patientNb, unit)
		if scanErr != nil {
			err = scanErr
			err = fmt.Errorf("while scanning SQL record: %s", err.Error())
			return
		}

		var queryResult StatsObservation

		queryResult.Unit = *unit

		queryResult.NumericValue, err = strconv.ParseFloat(*numericValue, 64)
		if err != nil {
			err = fmt.Errorf("error while converting numerical value %s for the (concept or modifier) with code (%s)", *numericValue, code)
			return
		}

		queryResult.PatientNumber, err = strconv.ParseInt(*patientNb, 10, 64)
		if err != nil {
			err = fmt.Errorf("error while parsing the patient identifier %s for the (concept or modifier) with code (%s)", *patientNb, code)
			return
		}

		statsObservations = append(statsObservations, queryResult)
	}

	return

}

// convertIntListToString is used to convert a list of int into a list of integer argument for a sql query.
// For instance the output of this function will be accepted by ANY($n::integer[]) where `n` is the index of the parameter in a SQL argument.
func convertIntListToString(intList []int64) string {
	strList := make([]string, len(intList))
	for i, num := range intList {
		strList[i] = strconv.FormatInt(num, 10)
	}
	return "{" + strings.Join(strList, ",") + "}"
}

/*
* This query will return the numerical values from all observations where
* the patient_num is contained within the list passed as argument (the list is in principle a list of patient from a specific cohort).

TODO In the same way I gathered the schema and table in which the ontology is contained, gather the schema in which observations are contained.
For the moment I hardcode the table and schema.

We only keep rows where nval_num is exactly equal to a specific values hence the required value of TVAL_CHAR.
We could keep values which are GE or LE or L or G the problem is that we would need open brackets for intervals.
VALTYPE_CD = 'N' because we only care about numerical values.
*/
const sqlStart string = `
SELECT nval_num, patient_num, units_cd FROM i2b2demodata.observation_fact
	WHERE `

const sqlModifier string = sqlStart + ` modifier_cd = $1 ` + sqlEnd
const sqlConcept string = sqlStart + ` concept_cd = $1 ` + sqlEnd

const sqlEnd = ` AND valtype_cd = 'N' AND tval_char = 'E' AND nval_num is not null AND units_cd is not null AND units_cd != '@'
AND nval_num >= $2 `

const sqlCohortFilter = ` AND patient_num = ANY($3::integer[]) `
