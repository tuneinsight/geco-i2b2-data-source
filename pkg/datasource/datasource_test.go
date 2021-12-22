package datasource

import (
	"testing"

	gecomodels "github.com/ldsec/geco/pkg/models"
	gecosdk "github.com/ldsec/geco/pkg/sdk"
	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
)

func getTestDataSource(t *testing.T) *I2b2DataSource {
	config := make(map[string]string)
	config["i2b2.api.url"] = "http://localhost:8080/i2b2/services"
	config["i2b2.api.domain"] = "i2b2demo"
	config["i2b2.api.username"] = "demo"
	config["i2b2.api.password"] = "changeme"
	config["i2b2.api.project"] = "Demo"
	config["i2b2.api.wait-time"] = "10s"
	config["i2b2.api.ont-max-elements"] = "200"

	config["db.host"] = "localhost"
	config["db.port"] = "5432"
	config["db.db-name"] = "i2b2"
	config["db.schema-name"] = "gecodatasource"
	config["db.user"] = "postgres"
	config["db.password"] = "postgres"

	logrus.StandardLogger().SetLevel(logrus.DebugLevel)
	ds, err := NewI2b2DataSource(logrus.StandardLogger(), config)
	require.NoError(t, err)
	return ds.(*I2b2DataSource)
}

func TestQuery(t *testing.T) {
	ds := getTestDataSource(t)
	params := `{"path": "/", "operation": "children"}`
	res, _, err := ds.Query("testUser", "searchConcept", []byte(params), nil)
	require.NoError(t, err)
	t.Logf("result: %v", string(res))
}

func TestQueryDataObject(t *testing.T) {
	ds := getTestDataSource(t)
	params := `{"id": "0", "definition": {"panels": [{"conceptItems": [{"queryTerm": "/TEST/test/1/"}]}]}}`
	sharedIDs := map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID{outputNameExploreQueryCount: "countSharedID", outputNameExploreQueryPatientList: "patientListSharedID"}
	res, do, err := ds.Query("testUser", "exploreQuery", []byte(params), sharedIDs)
	require.NoError(t, err)

	require.EqualValues(t, 3, *do[0].IntValue)
	require.EqualValues(t, "countSharedID", do[0].SharedID)
	require.EqualValues(t, outputNameExploreQueryCount, do[0].OutputName)

	require.InDeltaSlice(t, []int64{1, 2, 3}, do[1].IntVector, 0.001)
	require.EqualValues(t, "patientListSharedID", do[1].SharedID)
	require.EqualValues(t, outputNameExploreQueryPatientList, do[1].OutputName)

	t.Logf("result: %v", string(res))
	t.Logf("do: %+v", do)
}

func TestWorkflow(t *testing.T) {
	// todo: impl. workflow full
}
