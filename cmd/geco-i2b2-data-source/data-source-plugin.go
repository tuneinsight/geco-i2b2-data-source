package main

import (
	"github.com/ldsec/geco-i2b2-data-source/pkg"
	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2datasource"
)

// DataSourcePlugin exports an instance of the GeCo i2b2 data source for the plugin.
var DataSourcePlugin pkg.DataSource = i2b2datasource.I2b2DataSource{}
