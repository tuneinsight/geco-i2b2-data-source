package database

import (
	"database/sql"
	"fmt"
	"strconv"

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
func (db PostgresDatabase) RetrieveObservationsForConcept(code string, patientSetID, minObservations int64) (statsObservations []StatsObservation, err error) {
	logrus.Debugf("executing stats SQL query: %s, concept: %s, patientSetID: %v", "i2b2demodata.get_obs_for_concept", code, patientSetID)

	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "RetrieveObservationsForConcept")
	defer span.End()

	return db.retrieveObservations("SELECT * FROM i2b2demodata.get_obs_for_concept($1, $2, $3);", code, patientSetID, minObservations)
}

// RetrieveObservationsForModifier returns the numerical values that correspond to the modifier passed as argument for the specified cohort.
func (db PostgresDatabase) RetrieveObservationsForModifier(code string, patientSetID, minObservations int64) (statsObservations []StatsObservation, err error) {
	logrus.Debugf("executing stats SQL query: %s, modifier: %s, patientSetID: %v", "i2b2demodata.get_obs_for_modifier", code, patientSetID)

	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "RetrieveObservationsForModifier")
	defer span.End()

	return db.retrieveObservations("SELECT * FROM i2b2demodata.get_obs_for_modifier($1, $2, $3);", code, patientSetID, minObservations)
}

// retrieveObservations returns the numerical values that correspond to the concept or modifier whose code is passed as argument for the specified cohort.
func (db PostgresDatabase) retrieveObservations(sqlQuery, code string, patientSetID, minObservations int64) (statsObservations []StatsObservation, err error) {

	span := telemetry.StartSpan(db.Ctx, "datasource:i2b2:database", "retrieveObservations")
	defer span.End()

	var rows *sql.Rows
	rows, err = db.handle.Query(sqlQuery, code, minObservations, patientSetID)

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
