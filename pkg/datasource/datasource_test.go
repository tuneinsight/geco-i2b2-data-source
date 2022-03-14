package datasource

import (
	"fmt"
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/database"
	gecomodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	gecosdk "github.com/tuneinsight/sdk-datasource/pkg/sdk"
)

func getDataSource(t *testing.T) *I2b2DataSource {
	config := make(map[string]interface{})
	config["i2b2.api.url"] = "http://localhost:8081/i2b2/services"
	config["i2b2.api.domain"] = "i2b2demo"
	config["i2b2.api.username"] = "demo"
	config["i2b2.api.password"] = "changeme"
	config["i2b2.api.project"] = "Demo"
	config["i2b2.api.wait-time"] = "10s"
	config["i2b2.api.ont-max-elements"] = "200"

	config["db.host"] = "localhost"
	config["db.port"] = "5433"
	config["db.db-name"] = "i2b2"
	config["db.schema-name"] = database.TestSchemaName
	config["db.user"] = "postgres"
	config["db.password"] = "postgres"

	logrus.StandardLogger().SetLevel(logrus.DebugLevel)
	manager := gecosdk.NewDBManager(gecosdk.DBManagerConfig{
		SleepingTimeBetweenAttemptsSeconds: 5,
		MaxConnectionAttempts:              3,
	})
	ds, err := NewI2b2DataSource("", "test", "test-geco-i2b2-ds", manager)
	require.NoError(t, err)
	err = ds.Config(logrus.StandardLogger(), config)
	require.NoError(t, err)

	err = ds.(*I2b2DataSource).db.TestLoadData()
	require.NoError(t, err)

	return ds.(*I2b2DataSource)
}

func dataSourceCleanUp(t *testing.T, ds *I2b2DataSource) {
	err := ds.db.TestCleanUp()
	require.NoError(t, err)
	err = ds.Close()
	require.NoError(t, err)
}

func TestQuery(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	params := `{"path": "/", "operation": "children"}`
	res, _, err := ds.Query("testUser", "searchConcept", []byte(params), nil)
	require.NoError(t, err)
	t.Logf("result: %v", string(res))
}

func TestQueryDataObject(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	params := `{"id": "99999999-9999-1122-0000-999999999999", "definition": {"panels": [{"conceptItems": [{"queryTerm": "/TEST/test/1/"}]}]}}`
	sharedIDs := map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID{
		outputNameExploreQueryCount:       "99999999-9999-9999-1111-999999999999",
		outputNameExploreQueryPatientList: "99999999-9999-9999-0000-999999999999",
	}
	res, do, err := ds.Query("testUser", "exploreQuery", []byte(params), sharedIDs)
	require.NoError(t, err)

	require.EqualValues(t, 3, *do[0].IntValue)
	require.EqualValues(t, "99999999-9999-9999-1111-999999999999", do[0].SharedID)
	require.EqualValues(t, outputNameExploreQueryCount, do[0].OutputName)

	require.InDeltaSlice(t, []int64{1, 2, 3}, do[1].IntVector, 0.001)
	require.EqualValues(t, "99999999-9999-9999-0000-999999999999", do[1].SharedID)
	require.EqualValues(t, outputNameExploreQueryPatientList, do[1].OutputName)

	t.Logf("result: %v", string(res))
	t.Logf("do: %+v", do)
}

func TestWorkflow(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	user := "testUser"

	// search the ontology by browsing it
	params := `{"path": "/", "operation": "children"}`
	res, do, err := ds.Query(user, "searchConcept", []byte(params), nil)
	require.NoError(t, err)
	require.Empty(t, do)
	require.Contains(t, string(res), "Test Ontology")

	params = `{"path": "/TEST/test/", "operation": "children"}`
	res, do, err = ds.Query(user, "searchConcept", []byte(params), nil)
	require.NoError(t, err)
	require.Empty(t, do)
	require.Contains(t, string(res), "Concept 1")

	params = `{"path": "/TEST/test/1/", "operation": "concept"}`
	res, do, err = ds.Query(user, "searchModifier", []byte(params), nil)
	require.NoError(t, err)
	require.Empty(t, do)
	require.Contains(t, string(res), "Modifier 1")

	// OR search the ontology by searching for a specific item.
	params = `{"searchString": "Modifier 1", "limit": "10"}`
	res, do, err = ds.Query(user, string(OperationSearchOntology), []byte(params), nil)
	require.NoError(t, err)
	require.Empty(t, do)
	require.Contains(t, string(res), "Modifier 1")

	// execute query
	queryID := "99999999-9999-9999-9999-999999999999"
	params = fmt.Sprintf(`{
		"id": "%v",
		"definition": {
			"panels": [
				{
					"conceptItems": [
						{
							"queryTerm": "/TEST/test/2/",
							"operator": "LIKE[contains]",
							"value": "cd",
							"type": "TEXT",
							"modifier": {
								"key": "/TEST/modifiers2/text/",
								"appliedPath": "/test/2/"
							}
						}
					]
				},{
					"conceptItems": [
						{
							"queryTerm": "/TEST/test/1/",
							"operator": "EQ",
							"value": "10",
							"type": "NUMBER"
						},{
							"queryTerm": "/TEST/test/3/",
							"operator": "EQ",
							"value": "20",
							"type": "NUMBER"
						}
					]
				}
			]
		}
	}`, queryID)
	sharedIDs := map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID{
		outputNameExploreQueryCount:       "99999999-9999-9999-1111-999999999999",
		outputNameExploreQueryPatientList: "99999999-9999-9999-0000-999999999999",
	}
	res, do, err = ds.Query(user, "exploreQuery", []byte(params), sharedIDs)
	require.NoError(t, err)
	require.EqualValues(t, 2, len(do))
	for i := range do {
		if do[i].OutputName == outputNameExploreQueryCount {
			require.EqualValues(t, 1, *do[i].IntValue)
		} else if do[i].OutputName == outputNameExploreQueryPatientList {
			require.Subset(t, do[i].IntVector, []int64{1})
		} else {
			require.Fail(t, "unexpected output name encountered")
		}
	}

	// save cohort
	params = fmt.Sprintf(`{"name": "mycohort", "exploreQueryID": "%s"}`, queryID)
	res, do, err = ds.Query(user, "addCohort", []byte(params), nil)
	require.NoError(t, err)
	require.Empty(t, do)
	require.EqualValues(t, "", string(res))

	params = `{}`
	res, do, err = ds.Query(user, "getCohorts", []byte(params), nil)
	require.NoError(t, err)
	require.Empty(t, do)
	require.Contains(t, string(res), "mycohort")

	params = fmt.Sprintf(`{"name": "mycohort", "exploreQueryID": "%s"}`, queryID)
	res, do, err = ds.Query(user, "deleteCohort", []byte(params), nil)
	require.NoError(t, err)
	require.Empty(t, do)
	require.EqualValues(t, "", string(res))

	params = `{"limit": 7}`
	res, do, err = ds.Query(user, "getCohorts", []byte(params), nil)
	require.NoError(t, err)
	require.Empty(t, do)
	require.NotContains(t, string(res), "mycohort")
}
