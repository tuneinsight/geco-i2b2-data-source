package database

import (
	"database/sql"
	"fmt"
)

// GetCohort retrieves a saved cohort from the database.
// Returns nil (not an error) if cohort does not exist.
func (db PostgresDatabase) GetCohort(cohortName string, exploreQueryID string) (cohort *SavedCohort, err error) {
	const getCohortStatement = `
		SELECT
			saved_cohort.name AS cohort_name,
			saved_cohort.create_date AS cohort_create_date,
			saved_cohort.explore_query_id AS explore_query_id,
			explore_query.create_date AS explore_query_create_date,
			explore_query.user_id AS  explore_query_user_id,
			explore_query.status AS explore_query_status,
			explore_query.definition AS explore_query_definition,
			explore_query.result_i2b2_patient_set_id AS result_i2b2_patient_set_id,
			explore_query.result_geco_shared_id_count AS result_geco_shared_id_count,
			explore_query.result_geco_shared_id_patient_list AS result_geco_shared_id_patient_list
		
		FROM explore_query 
			INNER JOIN saved_cohort ON explore_query.id = saved_cohort.explore_query_id
		
		WHERE saved_cohort.name = $1 AND saved_cohort.explore_query_id = $2;`

	var rows *sql.Rows
	if rows, err = db.handle.Query(getCohortStatement, cohortName, exploreQueryID); err != nil {
		return nil, fmt.Errorf("querying getCohortStatement: %v", err)
	}
	defer closeRows(rows, db.logger)

	if rows.Next() {
		cohort = new(SavedCohort)

		err = rows.Scan(
			&cohort.Name,
			&cohort.CreateDate,
			&cohort.ExploreQuery.ID,
			&cohort.ExploreQuery.CreateDate,
			&cohort.ExploreQuery.UserID,
			&cohort.ExploreQuery.Status,
			&cohort.ExploreQuery.Definition,
			&cohort.ExploreQuery.ResultI2b2PatientSetID,
			&cohort.ExploreQuery.ResultGecoSharedIDCount,
			&cohort.ExploreQuery.ResultGecoSharedIDPatientList,
		)
		if err != nil {
			return nil, fmt.Errorf("scanning row of getCohortStatement: %v", err)
		}
	} else {
		db.logger.Warnf("cohort not found (name: %v, explore query ID: %v)", cohortName, exploreQueryID)
	}
	return
}

// GetCohorts retrieves the saved cohorts of a user from the database.
func (db PostgresDatabase) GetCohorts(userID string, limit int) (cohorts []SavedCohort, err error) {
	const getCohortsStatement = `
		SELECT
			saved_cohort.name AS cohort_name,
			saved_cohort.create_date AS cohort_create_date,
			saved_cohort.explore_query_id AS explore_query_id,
			explore_query.create_date AS explore_query_create_date,
			explore_query.user_id AS  explore_query_user_id,
			explore_query.status AS explore_query_status,
			explore_query.definition AS explore_query_definition,
			explore_query.result_i2b2_patient_set_id AS result_i2b2_patient_set_id,
			explore_query.result_geco_shared_id_count AS result_geco_shared_id_count,
			explore_query.result_geco_shared_id_patient_list AS result_geco_shared_id_patient_list
		
		FROM explore_query
			INNER JOIN saved_cohort ON explore_query.id = saved_cohort.explore_query_id
		
		WHERE explore_query.user_id = $1 AND explore_query.status = 'success'
		ORDER BY saved_cohort.create_date DESC
		LIMIT $2;`

	var rows *sql.Rows
	if rows, err = db.handle.Query(getCohortsStatement, userID, limit); err != nil {
		return nil, fmt.Errorf("querying getCohortsStatement: %v", err)
	}
	defer closeRows(rows, db.logger)

	for rows.Next() {
		c := SavedCohort{}
		err = rows.Scan(
			&c.Name,
			&c.CreateDate,
			&c.ExploreQuery.ID,
			&c.ExploreQuery.CreateDate,
			&c.ExploreQuery.UserID,
			&c.ExploreQuery.Status,
			&c.ExploreQuery.Definition,
			&c.ExploreQuery.ResultI2b2PatientSetID,
			&c.ExploreQuery.ResultGecoSharedIDCount,
			&c.ExploreQuery.ResultGecoSharedIDPatientList,
		)
		if err != nil {
			return nil, fmt.Errorf("scanning row of getCohortsStatement: %v", err)
		}
		cohorts = append(cohorts, c)
	}
	db.logger.Infof("retrieved %v cohorts for user %v", len(cohorts), userID)
	return
}

// AddCohort adds a saved cohort for a user. Returns an error (due to foreign key violation) if the explore query does
// not exist, or if the provided user does not match.
func (db PostgresDatabase) AddCohort(userID, cohortName, exploreQueryID string) (err error) {
	const addCohortStatement = `
		INSERT INTO saved_cohort(name, create_date, explore_query_id)
			SELECT $2, NOW(), id FROM explore_query WHERE id = $3 AND user_id = $1;`

	if res, err := db.handle.Exec(addCohortStatement, userID, cohortName, exploreQueryID); err != nil {
		return fmt.Errorf("executing addCohortStatement: %v", err)
	} else if rowsAffected, err := res.RowsAffected(); err != nil {
		return fmt.Errorf("database error: %v", err)
	} else if rowsAffected == 0 {
		return fmt.Errorf("explore query does not exist")
	}
	db.logger.Infof("added cohort (name: %v, explore query ID: %v)", cohortName, exploreQueryID)
	return
}

// DeleteCohort deletes a saved cohort for a user.
func (db PostgresDatabase) DeleteCohort(userID, cohortName, exploreQueryID string) (err error) {
	const deleteCohortStatement = `
		DELETE FROM saved_cohort 
			USING explore_query
			WHERE 
			explore_query.user_id = $1 AND
		  	saved_cohort.name = $2 AND
			saved_cohort.explore_query_id = $3 AND explore_query.id = $3;`

	if res, err := db.handle.Exec(deleteCohortStatement, userID, cohortName, exploreQueryID); err != nil {
		return fmt.Errorf("executing deleteCohortStatement: %v", err)
	} else if rowsAffected, err := res.RowsAffected(); err != nil {
		return fmt.Errorf("database error: %v", err)
	} else if rowsAffected == 0 {
		return fmt.Errorf("cohort does not exist")
	}
	db.logger.Infof("deleted cohort (name: %v, explore query ID: %v)", cohortName, exploreQueryID)
	return
}
