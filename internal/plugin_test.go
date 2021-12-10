package internal

import (
	"plugin"
	"testing"

	"github.com/ldsec/geco-i2b2-data-source/pkg"
	"github.com/ldsec/geco/pkg/common/configuration"
	"github.com/ldsec/geco/pkg/datamanager"
	"github.com/sirupsen/logrus"
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

	config := make(map[string]string)
	config["i2b2.api.url"] = "http://localhost:8080/i2b2/services"
	config["i2b2.api.domain"] = "i2b2demo"
	config["i2b2.api.username"] = "demo"
	config["i2b2.api.password"] = "changeme"
	config["i2b2.api.project"] = "Demo"
	config["i2b2.api.wait-time"] = "10s"
	config["i2b2.api.ont-max-elements"] = "200"

	logrus.StandardLogger().SetLevel(logrus.DebugLevel)
	err = (*ds).Init(dm, logrus.StandardLogger(), config)
	require.NoError(t, err)

	params := make(map[string]interface{})
	params["path"] = "/"
	params["operation"] = "children"
	_, err = (*ds).Query("test", "searchConcept", params, nil)
	require.NoError(t, err)
}
