package main

import (
	"github.com/ldsec/geco-i2b2-data-source/pkg/datasource"
	"github.com/ldsec/geco/pkg/sdk"
)

// DataSourcePluginFactory exports a factory function compatible with GeCo data source plugin SDK.
var DataSourcePluginFactory sdk.DataSourcePluginFactory = datasource.NewI2b2DataSource
