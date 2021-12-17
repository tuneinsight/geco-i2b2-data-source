package i2b2datasource

import (
	"testing"

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

	logrus.StandardLogger().SetLevel(logrus.DebugLevel)
	ds, err := NewI2b2DataSource(logrus.StandardLogger(), config)
	require.NoError(t, err)
	return ds.(*I2b2DataSource)
}

func TestQuery(t *testing.T) {
	ds := getTestDataSource(t)
	params := `{"path": "/", "operation": "children"}`
	res, _, err := ds.Query("testUser", "searchConcept", []byte(params))
	require.NoError(t, err)
	t.Logf("result: %v", string(res))
}

func TestQueryDataObject(t *testing.T) {
	ds := getTestDataSource(t)
	params := `{"id": "0", "definition": {"panels": [{"conceptItems": [{"queryTerm": "/TEST/test/1/"}]}]}}`
	res, do, err := ds.Query("testUser", "exploreQuery", []byte(params))
	require.NoError(t, err)
	require.EqualValues(t, 3, *do["count"].IntValue)
	require.InDeltaSlice(t, []int64{1, 2, 3}, do["patientList"].IntVector, 0.001)
	t.Logf("result: %v", string(res))
	t.Logf("do: %+v", do)
}
