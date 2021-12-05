package i2b2datasource

import (
	"testing"

	"github.com/ldsec/geco/pkg/common/configuration"
	"github.com/ldsec/geco/pkg/datamanager"
	"github.com/stretchr/testify/require"
)

func TestDataManager(t *testing.T) {

	ds := I2b2DataSource{}

	dm, err := datamanager.NewDataManager(configuration.NewTestDataManagerConfig())
	require.NoError(t, err)

	err = ds.Init(dm, nil)
	require.NoError(t, err)

	doId, err := dm.AddDataObject(datamanager.NewFloatVector([]float64{0, 1, 2, 3, 4}), false)
	require.NoError(t, err)
	t.Logf("test data object ID is %v", doId)

	do, err := dm.GetDataObject(doId)
	require.NoError(t, err)
	require.Equal(t, doId, do.ID)
	require.Equal(t, datamanager.FloatVector, do.Type)

	data, err := do.FloatVector()
	require.NoError(t, err)
	require.InDeltaSlice(t, []float64{0, 1, 2, 3, 4}, data, 0.0001)
}
