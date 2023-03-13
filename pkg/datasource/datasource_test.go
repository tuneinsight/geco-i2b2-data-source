package datasource

import (
	"encoding/json"
	"fmt"
	"os"
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/database"
	gecomodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk"
	gecosdk "github.com/tuneinsight/sdk-datasource/pkg/sdk"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk/credentials"
)

func getDataSource(t *testing.T) *I2b2DataSource {
	config := make(map[string]interface{})
	config["i2b2.api.url"] = "http://localhost:8081/i2b2/services"
	config["i2b2.api.domain"] = "i2b2demo"
	config["i2b2.api.project"] = "Demo"
	config["i2b2.api.wait-time"] = "10s"
	config["i2b2.api.ont-max-elements"] = "200"

	config["db.host"] = "localhost"
	config["db.port"] = "5433"
	config["db.db-name"] = "i2b2"
	config["db.schema-name"] = database.TestSchemaName

	logrus.StandardLogger().SetLevel(logrus.DebugLevel)
	manager := gecosdk.NewDBManager(gecosdk.DBManagerConfig{
		SleepingTimeBetweenAttemptsSeconds: 5,
		MaxConnectionAttempts:              3,
	})
	credProvider := credentials.NewLocal(map[string]*credentials.Credentials{
		DBCredentialsID:   credentials.NewCredentials("postgres", "postgres", ""),
		I2B2CredentialsID: credentials.NewCredentials("demo", "changeme", ""),
	})

	dsc := gecosdk.NewDataSourceCore(
		gecosdk.NewMetadataDB("", "test", "test-i2b2-ds", DataSourceType, ""),
		gecosdk.NewMetadataStorage(credProvider))
	ds, err := NewI2b2DataSource(dsc, nil, manager)
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
	results, err := ds.Query("testUser", map[string]interface{}{sdk.QueryOperation: "searchConcept", sdk.QueryParams: params})
	res := results[sdk.DefaultResultKey].([]byte)
	require.NoError(t, err)
	t.Logf("result: %v", string(res))
}

func TestQueryDataObject(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	sharedIDs := map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID{
		outputNameExploreQueryCount:       "99999999-9999-9999-1111-999999999999",
		outputNameExploreQueryPatientList: "99999999-9999-9999-0000-999999999999",
	}

	jsonSharedIDs, _ := json.Marshal(sharedIDs)

	params := `{
	"id": "99999999-9999-1122-0000-999999999999",
	"patientList": true,
	"definition": {
		"selectionPanels": [{
			"conceptItems": [{
				"queryTerm": "/TEST/test/1/"
			}]
		}]
	},
	"outputDataObjectsSharedIDs": ` + string(jsonSharedIDs) + `
}`

	results, err := ds.Query("testUser", map[string]interface{}{sdk.QueryOperation: "exploreQuery", sdk.QueryParams: params})
	res := results[sdk.DefaultResultKey].([]byte)
	require.NoError(t, err)
	do := results[sdk.OutputDataObjectsKey].([]sdk.DataObject)

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

	// test with local provider
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	// test with Azure Key Vault provider
	// credentials of the TI test AKV
	os.Setenv("AZURE_TENANT_ID", "e6021d6c-8bdc-4c91-b88f-e3333caae8b8")
	os.Setenv("AZURE_CLIENT_ID", "00d75d9b-9524-4428-bd6a-a6dc2a08ac19")
	os.Setenv("AZURE_CLIENT_SECRET", "P7I8Q~KpPiCphM2LOe25Wil6c80vHo3KJqSr3b~r")
	os.Setenv("AZURE_KEY_VAULT_URI", "https://ti-test-vault.vault.azure.net/")

	credProvider, err := credentials.NewAzureKeyVault(map[string]string{
		// this maps the data source creds IDs with the IDs of the secrets that have been created in Azure
		I2B2CredentialsID: "test-i2b2-credentials",
		DBCredentialsID:   "test-i2b2-db-credentials",
	})
	require.NoError(t, err)
	ds.CredentialsProvider = credProvider

	testWorkflow(t, ds)

}

func testWorkflow(t *testing.T, ds *I2b2DataSource) {

	user := "testUser"

	// search the ontology by browsing it
	params := `{"path": "/", "operation": "children"}`
	results, err := ds.Query(user, map[string]interface{}{sdk.QueryOperation: "searchConcept", sdk.QueryParams: params})
	res := results[sdk.DefaultResultKey].([]byte)
	require.NoError(t, err)

	require.Contains(t, string(res), "Test Ontology")

	params = `{"path": "/TEST/test/", "operation": "children"}`
	results, err = ds.Query(user, map[string]interface{}{sdk.QueryOperation: "searchConcept", sdk.QueryParams: params})
	res = results[sdk.DefaultResultKey].([]byte)
	require.NoError(t, err)

	require.Contains(t, string(res), "Concept 1")

	params = `{"path": "/TEST/test/1/", "operation": "concept"}`
	results, err = ds.Query(user, map[string]interface{}{sdk.QueryOperation: "searchModifier", sdk.QueryParams: params})
	res = results[sdk.DefaultResultKey].([]byte)
	require.NoError(t, err)

	require.Contains(t, string(res), "Modifier 1")

	// OR search the ontology by searching for a specific item.
	params = `{"searchString": "Modifier 1", "limit": "10"}`
	results, err = ds.Query(user, map[string]interface{}{sdk.QueryOperation: string(OperationSearchOntology), sdk.QueryParams: params})
	res = results[sdk.DefaultResultKey].([]byte)
	require.NoError(t, err)

	require.Contains(t, string(res), "Modifier 1")

	sharedIDs := map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID{
		outputNameExploreQueryCount:       "99999999-9999-9999-1111-999999999999",
		outputNameExploreQueryPatientList: "99999999-9999-9999-0000-999999999999",
	}
	jsonSharedIDs, _ := json.Marshal(sharedIDs)

	// execute query
	queryID := "99999999-9999-9999-9999-999999999999"
	params = fmt.Sprintf(`{
		"id": "%v",
		"patientList": true,
		"definition": {
			"selectionPanels": [
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
		},
		"outputDataObjectsSharedIDs": `+string(jsonSharedIDs)+`
	}`, queryID)

	results, err = ds.Query(user, map[string]interface{}{sdk.QueryOperation: "exploreQuery", sdk.QueryParams: params})
	require.NoError(t, err)

	do := results[sdk.OutputDataObjectsKey].([]sdk.DataObject)
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

	projectID := "99999999-9999-9999-1111-999999999999"
	params = fmt.Sprintf(`{"name": "mycohort", "exploreQueryID": "%s", "projectID": "%s"}`, queryID, projectID)
	results, err = ds.Query(user, map[string]interface{}{sdk.QueryOperation: "addCohort", sdk.QueryParams: params})
	res = results[sdk.DefaultResultKey].([]byte)
	require.NoError(t, err)
	require.EqualValues(t, "", string(res))

	params = fmt.Sprintf(`{"projectID": "%s"}`, projectID)
	results, err = ds.Query(user, map[string]interface{}{sdk.QueryOperation: "getCohorts", sdk.QueryParams: params})
	res = results[sdk.DefaultResultKey].([]byte)
	require.NoError(t, err)
	require.Contains(t, string(res), "mycohort")

	params = fmt.Sprintf(`{"name": "mycohort", "exploreQueryID": "%s", "projectID": "%s"}`, queryID, projectID)
	results, err = ds.Query(user, map[string]interface{}{sdk.QueryOperation: "deleteCohort", sdk.QueryParams: params})
	res = results[sdk.DefaultResultKey].([]byte)
	require.NoError(t, err)
	require.EqualValues(t, "", string(res))

	params = fmt.Sprintf(`{"projectID": "%s", "limit": 7}`, projectID)
	results, err = ds.Query(user, map[string]interface{}{sdk.QueryOperation: "getCohorts", sdk.QueryParams: params})
	res = results[sdk.DefaultResultKey].([]byte)
	require.NoError(t, err)
	require.NotContains(t, string(res), "mycohort")

}
