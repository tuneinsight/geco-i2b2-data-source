package main

import (
	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2datasource"
	"github.com/ldsec/geco/pkg/sdk"
)

// DataSourcePluginFactory exports a factory function compatible with GeCo data source plugin SDK.
var DataSourcePluginFactory sdk.DataSourcePluginFactory = i2b2datasource.NewI2b2DataSource
