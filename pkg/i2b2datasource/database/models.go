package database

import "database/sql"

// SavedCohort is a cohort such as stored in the database.
type SavedCohort struct {
	Name         string
	CreateDate   string
	ExploreQuery ExploreQuery
}

// ExploreQuery is an explore query such as stored in the database.
type ExploreQuery struct {
	ID                            string
	CreateDate                    string
	UserID                        string
	Status                        string
	Definition                    string
	ResultI2b2PatientSetID        sql.NullInt64
	ResultGecoSharedIDCount       sql.NullString
	ResultGecoSharedIDPatientList sql.NullString
}
