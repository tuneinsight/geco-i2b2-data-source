package database

import (
	"database/sql"
	"fmt"
)

// GetExploreQuery retrieves an explore query from the database.
// Returns nil (not an error) if query does not exist.
func (db PostgresDatabase) GetExploreQuery(id string) (query *ExploreQuery, err error) {
	const getExploreQueryStatement = `
		SELECT 
			id,
			create_date,
			user_id,
			status,
			definition,
			result_i2b2_patient_set_id,
			result_geco_shared_id_count,
			result_geco_shared_id_patient_list
	
		FROM explore_query
		WHERE id = $1;`

	var rows *sql.Rows
	if rows, err = db.handle.Query(getExploreQueryStatement, id); err != nil {
		return nil, fmt.Errorf("querying getExploreQueryStatement: %v", err)
	}
	defer closeRows(rows, db.logger)

	if rows.Next() {
		query = new(ExploreQuery)

		err = rows.Scan(
			&query.ID,
			&query.CreateDate,
			&query.UserID,
			&query.Status,
			&query.Definition,
			&query.ResultI2b2PatientSetID,
			&query.ResultGecoSharedIDCount,
			&query.ResultGecoSharedIDPatientList,
		)
		if err != nil {
			return nil, fmt.Errorf("scanning row of getExploreQueryStatement: %v", err)
		}
	} else {
		db.logger.Warnf("explore query not found (ID: %v)", id)
	}
	return
}

// AddExploreQuery adds an explore query with the requested status.
func (db PostgresDatabase) AddExploreQuery(userID, queryID, queryDefinition string) (err error) {
	const addExploreQueryStatement = `
		INSERT INTO explore_query(id, create_date, user_id, status, definition, result_i2b2_patient_set_id,
		result_geco_shared_id_count, result_geco_shared_id_patient_list) VALUES
		($1, NOW(), $2, 'requested', $3, NULL, NULL, NULL);`

	if _, err = db.handle.Exec(addExploreQueryStatement, queryID, userID, queryDefinition); err != nil {
		return fmt.Errorf("executing addExploreQueryStatement: %v", err)
	}
	db.logger.Infof("added explore query (ID: %v)", queryID)
	return
}

// SetExploreQueryRunning sets the running status to an explore query.
func (db PostgresDatabase) SetExploreQueryRunning(userID, queryID string) error {
	return db.setExploreQueryStatus("running", userID, queryID)
}

// SetExploreQueryError sets the error status to an explore query.
func (db PostgresDatabase) SetExploreQueryError(userID, queryID string) error {
	return db.setExploreQueryStatus("error", userID, queryID)
}

// SetExploreQuerySuccess sets the success status to an explore query and stores its results.
func (db PostgresDatabase) SetExploreQuerySuccess(userID, queryID string, i2b2PatientSetID int64, gecoSharedIDCount, gecoSharedIDPatientList string) error {
	const setExploreQuerySuccessStatement = `
		UPDATE explore_query SET 
			result_i2b2_patient_set_id = $3,
			result_geco_shared_id_count = $4,
			result_geco_shared_id_patient_list = $5

		WHERE user_id = $1 AND id = $2;`

	if err := db.setExploreQueryStatus("success", userID, queryID); err != nil {
		return err
	} else if _, err := db.handle.Exec(setExploreQuerySuccessStatement, userID, queryID, i2b2PatientSetID, gecoSharedIDCount, gecoSharedIDPatientList); err != nil {
		return fmt.Errorf("executing setExploreQuerySuccessStatement: %v", err)
	}

	db.logger.Infof("updated explore query results (ID: %v)", queryID)
	return nil
}

// setExploreQueryStatus sets the status of an explore query.
func (db PostgresDatabase) setExploreQueryStatus(status, userID, queryID string) (err error) {
	const setExploreQueryStatusStatement = `
		UPDATE explore_query SET status = $1 WHERE user_id = $2 AND id = $3;`

	if res, err := db.handle.Exec(setExploreQueryStatusStatement, status, userID, queryID); err != nil {
		return fmt.Errorf("executing setExploreQueryStatusStatement: %v", err)
	} else if rowsAffected, err := res.RowsAffected(); err != nil {
		return fmt.Errorf("database error: %v", err)
	} else if rowsAffected == 0 {
		return fmt.Errorf("explore query does not exist")
	}
	db.logger.Infof("updated explore query status to %v (ID: %v)", status, queryID)
	return
}
