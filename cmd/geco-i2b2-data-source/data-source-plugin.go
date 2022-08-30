package main

import (
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk"
)

// DataSourceType is the type of the data source.
var DataSourceType = datasource.DataSourceType

// DataSourcePluginFactory exports a factory function compatible with the TI Note data source plugin SDK.
var DataSourcePluginFactory sdk.DataSourceFactory = datasource.NewI2b2DataSource
