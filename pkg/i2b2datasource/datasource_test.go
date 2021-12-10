package i2b2datasource

import (
	"testing"

	"github.com/ldsec/geco/pkg/common/configuration"
	"github.com/ldsec/geco/pkg/datamanager"
	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
)

func getTestDataSource(t *testing.T) I2b2DataSource {
	ds := I2b2DataSource{}

	dm, err := datamanager.NewDataManager(configuration.NewTestDataManagerConfig())
	require.NoError(t, err)

	config := make(map[string]string)
	config["i2b2.api.url"] = "http://localhost:8080/i2b2/services"
	config["i2b2.api.domain"] = "i2b2demo"
	config["i2b2.api.username"] = "demo"
	config["i2b2.api.password"] = "changeme"
	config["i2b2.api.project"] = "Demo"
	config["i2b2.api.wait-time"] = "10s"
	config["i2b2.api.ont-max-elements"] = "200"

	logrus.StandardLogger().SetLevel(logrus.DebugLevel)
	err = ds.Init(dm, logrus.StandardLogger(), config)
	require.NoError(t, err)
	return ds
}

func TestDataManager(t *testing.T) {

	ds := getTestDataSource(t)

	doId, err := ds.dm.AddDataObject(datamanager.NewFloatVector([]float64{0, 1, 2, 3, 4}), false)
	require.NoError(t, err)
	t.Logf("test data object ID is %v", doId)

	do, err := ds.dm.GetDataObject(doId)
	require.NoError(t, err)
	require.Equal(t, doId, do.ID)
	require.Equal(t, datamanager.FloatVector, do.Type)

	data, err := do.FloatVector()
	require.NoError(t, err)
	require.InDeltaSlice(t, []float64{0, 1, 2, 3, 4}, data, 0.0001)
}
