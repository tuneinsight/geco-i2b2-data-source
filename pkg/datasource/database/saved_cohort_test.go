package database

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestGetCohort(t *testing.T) {
	db := getDB(t)
	defer dbCleanUp(t, db)

	cohort1, err := db.GetCohort("cohort1", "11111111-1111-1111-1111-111111111111")
	require.NoError(t, err)
	require.EqualValues(t, "cohort1", cohort1.Name)
	require.EqualValues(t, "testuser1", cohort1.ExploreQuery.UserID)
	t.Logf("%+v", cohort1)

	cohort3, err := db.GetCohort("cohort3", "33333333-3333-3333-3333-333333333333")
	require.NoError(t, err)
	require.EqualValues(t, "cohort3", cohort3.Name)
	require.EqualValues(t, "testuser2", cohort3.ExploreQuery.UserID)
	t.Logf("%+v", cohort3)

	cohortNotFound, err := db.GetCohort("cohort1", "11111111-1111-9999-1111-111111111111")
	require.NoError(t, err)
	require.Nil(t, cohortNotFound)
}

func TestGetCohorts(t *testing.T) {
	db := getDB(t)
	defer dbCleanUp(t, db)

	cohorts1, err := db.GetCohorts("testuser1", 5)
	require.NoError(t, err)
	require.EqualValues(t, 1, len(cohorts1))
	require.EqualValues(t, "cohort1", cohorts1[0].Name)

	cohorts2, err := db.GetCohorts("testuser2", 5)
	require.NoError(t, err)
	require.EqualValues(t, 2, len(cohorts2))
	require.EqualValues(t, "cohort4", cohorts2[0].Name)
	require.EqualValues(t, "cohort3", cohorts2[1].Name)
}

func TestAddCohort(t *testing.T) {
	db := getDB(t)
	defer dbCleanUp(t, db)

	err := db.AddCohort("notvalid", "cohort0", "00000000-0000-0000-0000-000000000000")
	require.Error(t, err)
	t.Logf("%v", err)

	err = db.AddCohort("testuser1", "cohort0", "00000000-0000-0000-0000-000000000000")
	require.NoError(t, err)

	cohort0, err := db.GetCohort("cohort0", "00000000-0000-0000-0000-000000000000")
	require.NoError(t, err)
	require.EqualValues(t, "cohort0", cohort0.Name)
	require.EqualValues(t, "testuser1", cohort0.ExploreQuery.UserID)
	t.Logf("%+v", cohort0)

	err = db.AddCohort("testuser1", "cohort0", "00000000-0000-0000-9999-000000000000")
	require.Error(t, err)
	t.Logf("%v", err)
}

func TestDeleteCohort(t *testing.T) {
	db := getDB(t)
	defer dbCleanUp(t, db)

	cohortFound, err := db.GetCohort("cohort1", "11111111-1111-1111-1111-111111111111")
	require.NoError(t, err)
	require.EqualValues(t, "cohort1", cohortFound.Name)

	err = db.DeleteCohort("testuser2", "cohort1", "11111111-1111-1111-1111-111111111111")
	require.Error(t, err)
	t.Logf("%v", err)

	err = db.DeleteCohort("testuser1", "cohort1", "11111111-1111-1111-1111-111111111111")
	require.NoError(t, err)

	cohortNotFound, err := db.GetCohort("cohort1", "11111111-1111-1111-1111-111111111111")
	require.NoError(t, err)
	require.Nil(t, cohortNotFound)

	err = db.DeleteCohort("testuser1", "cohort2", "11111111-1111-1111-1111-111111111111")
	require.Error(t, err)
	t.Logf("%v", err)
}
