package internal

import (
	"plugin"
	"testing"

	"github.com/ldsec/geco-i2b2-data-source/pkg"
	"github.com/ldsec/geco/pkg/common/configuration"
	"github.com/ldsec/geco/pkg/datamanager"
	"github.com/stretchr/testify/require"
)

func TestPlugin(t *testing.T) {
	p, err := plugin.Open("../build/geco-i2b2-data-source.so")
	require.NoError(t, err)

	dsSymbol, err := p.Lookup("DataSourcePlugin")
	require.NoError(t, err)

	ds, ok := dsSymbol.(*pkg.DataSource)
	require.True(t, ok)

	dm, err := datamanager.NewDataManager(configuration.NewTestDataManagerConfig())
	require.NoError(t, err)

	err = (*ds).Init(dm, nil)
	require.NoError(t, err)

	_, err = (*ds).Query("", "", nil, nil)
	require.NoError(t, err)
}
