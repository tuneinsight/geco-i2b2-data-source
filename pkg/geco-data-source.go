package pkg

import (
	"github.com/ldsec/geco/pkg/datamanager"
	"github.com/sirupsen/logrus"
)

// todo: move this interface to geco once finalized, e.g. sdk

// DataSource defines a GeCo data source plugin. The plugin must export a variable named DataSourcePlugin of the
// type DataSource to be compatible.
type DataSource interface {

	// Init the data source with the provided configuration.
	Init(dm *datamanager.DataManager, logger logrus.FieldLogger, config map[string]string) error

	// Query data source with a specific operation.
	Query(userID string, operation string, parameters map[string]interface{}, resultsSharedIds map[string]string) (results map[string]interface{}, err error)
}
