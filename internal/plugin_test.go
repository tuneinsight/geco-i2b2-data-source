package internal

import (
	"plugin"
	"testing"

	gecoconf "github.com/ldsec/geco/pkg/common/configuration"
	"github.com/ldsec/geco/pkg/datamanager"
	gecosdk "github.com/ldsec/geco/pkg/sdk"
	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
)

const pluginPath = "../build/geco-i2b2-data-source.so"

func getTestConfig() map[string]string {
	config := make(map[string]string)
	config["i2b2.api.url"] = "http://localhost:8081/i2b2/services"
	config["i2b2.api.domain"] = "i2b2demo"
	config["i2b2.api.username"] = "demo"
	config["i2b2.api.password"] = "changeme"
	config["i2b2.api.project"] = "Demo"
	config["i2b2.api.wait-time"] = "10s"
	config["i2b2.api.ont-max-elements"] = "200"

	config["db.host"] = "localhost"
	config["db.port"] = "5432"
	config["db.db-name"] = "i2b2"
	config["db.schema-name"] = "gecodatasourceplugintest"
	config["db.user"] = "postgres"
	config["db.password"] = "postgres"
	return config
}

func TestPlugin(t *testing.T) {
	p, err := plugin.Open(pluginPath)
	require.NoError(t, err)

	dsTypeSymbol, err := p.Lookup("DataSourceType")
	require.NoError(t, err)

	dsType, ok := dsTypeSymbol.(*gecosdk.DataSourceType)
	require.True(t, ok)
	require.EqualValues(t, "i2b2-geco", *dsType)

	dsSymbol, err := p.Lookup("DataSourcePluginFactory")
	require.NoError(t, err)

	pluginFactory, ok := dsSymbol.(*gecosdk.DataSourcePluginFactory)
	t.Logf("%T", pluginFactory)
	t.Logf("%T", dsSymbol)
	require.True(t, ok)

	config := getTestConfig()

	logrus.StandardLogger().SetLevel(logrus.DebugLevel)
	ds, err := (*pluginFactory)(logrus.StandardLogger(), config)
	require.NoError(t, err)

	params := `{"path": "/", "operation": "children"}`
	res, _, err := ds.Query("testUser", "searchConcept", []byte(params), nil)
	require.NoError(t, err)
	t.Logf("result: %v", string(res))
}

func TestPluginDataManager(t *testing.T) {
	dm, err := datamanager.NewDataManager(gecoconf.NewTestDataManagerConfig())
	require.NoError(t, err)

	err = datamanager.LoadDataSourcePlugin(pluginPath)
	require.NoError(t, err)

	config := getTestConfig()
	ds, err := dm.NewDataSource("", "i2b2-geco-test", "test", "i2b2-geco", config, false)
	require.NoError(t, err)

	params := `{"path": "/", "operation": "children"}`
	res, err := ds.Query("testUser", "searchConcept", []byte(params), nil)
	require.NoError(t, err)
	t.Logf("result: %v", string(res))

	dsFound, err := dm.GetDataSource(ds.UniqueID())
	require.Equal(t, &ds, dsFound)
}
