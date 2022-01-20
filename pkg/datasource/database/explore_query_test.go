package database

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestGetExploreQuery(t *testing.T) {
	db := getDB(t)
	defer dbCleanUp(t, db)

	query1, err := db.GetExploreQuery("11111111-1111-1111-1111-111111111111")
	require.NoError(t, err)
	require.EqualValues(t, "testuser1", query1.UserID)
	t.Logf("%+v", query1)

	query3, err := db.GetExploreQuery("33333333-3333-3333-3333-333333333333")
	require.NoError(t, err)
	require.EqualValues(t, "testuser2", query3.UserID)
	t.Logf("%+v", query3)

	queryNotFound, err := db.GetExploreQuery("11111111-1111-9999-1111-111111111111")
	require.NoError(t, err)
	require.Nil(t, queryNotFound)
}

func TestExploreQuery(t *testing.T) {
	db := getDB(t)
	defer dbCleanUp(t, db)

	queryID := "11111111-7777-9999-1111-111111111111"
	err := db.AddExploreQuery("testUser5", queryID, "{}")
	require.NoError(t, err)

	query, err := db.GetExploreQuery(queryID)
	require.NoError(t, err)
	require.EqualValues(t, "testUser5", query.UserID)
	require.EqualValues(t, queryID, query.ID)
	require.EqualValues(t, "requested", query.Status)
	t.Logf("%+v", query)

	err = db.SetExploreQueryRunning("testUser5", queryID)
	require.NoError(t, err)
	query, err = db.GetExploreQuery(queryID)
	require.NoError(t, err)
	require.EqualValues(t, "running", query.Status)

	err = db.SetExploreQueryError("testUser5", queryID)
	require.NoError(t, err)
	query, err = db.GetExploreQuery(queryID)
	require.NoError(t, err)
	require.EqualValues(t, "error", query.Status)

	err = db.SetExploreQuerySuccess("testUser5", queryID, 7, "31133333-3333-3333-3333-333333333333", "33333333-3333-3333-3333-333333333223")
	require.NoError(t, err)
	query, err = db.GetExploreQuery(queryID)
	require.NoError(t, err)
	require.EqualValues(t, "success", query.Status)
	require.EqualValues(t, 7, query.ResultI2b2PatientSetID.Int64)

	err = db.SetExploreQueryRunning("asd", queryID)
	require.Error(t, err)
	t.Logf("%v", err)
}
