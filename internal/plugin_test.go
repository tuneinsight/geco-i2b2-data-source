package internal

import (
	"plugin"
	"testing"

	"github.com/ldsec/geco/pkg/sdk"
	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
)

func TestPlugin(t *testing.T) {
	p, err := plugin.Open("../build/geco-i2b2-data-source.so")
	require.NoError(t, err)

	dsSymbol, err := p.Lookup("DataSourcePluginFactory")
	require.NoError(t, err)

	pluginFactory, ok := dsSymbol.(*sdk.DataSourcePluginFactory)
	t.Logf("%T", pluginFactory)
	t.Logf("%T", dsSymbol)

	require.True(t, ok)

	config := make(map[string]string)
	config["i2b2.api.url"] = "http://localhost:8080/i2b2/services"
	config["i2b2.api.domain"] = "i2b2demo"
	config["i2b2.api.username"] = "demo"
	config["i2b2.api.password"] = "changeme"
	config["i2b2.api.project"] = "Demo"
	config["i2b2.api.wait-time"] = "10s"
	config["i2b2.api.ont-max-elements"] = "200"

	logrus.StandardLogger().SetLevel(logrus.DebugLevel)
	ds, err := (*pluginFactory)(logrus.StandardLogger(), config)
	require.NoError(t, err)

	params := `{"path": "/", "operation": "children"}`
	res, _, err := ds.Query("testUser", "searchConcept", []byte(params), nil)
	require.NoError(t, err)
	t.Logf("result: %v", string(res))
}
