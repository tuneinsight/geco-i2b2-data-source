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

// OntologyElement is an i2b2 ontology element as stored in the database.
type OntologyElement struct {
	FullName         string
	Name             string
	VisualAttributes string
	BaseCode         string
	MetaDataXML      sql.NullString
	Comment          string
	AppliedPath      string
	ID               int
}

// Events contains the number of events of interest and censoring events occurring at the same relative time.
type Events struct {
	EventsOfInterest int64
	CensoringEvents  int64
}
