package i2b2datasource

import (
	"fmt"

	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2"
	"github.com/ldsec/geco/pkg/datamanager"
	"github.com/sirupsen/logrus"
)

type I2b2DataSource struct {

	// dm is the GeCo data manager
	dm *datamanager.DataManager

	// logger is the logger from GeCo
	logger *logrus.Logger

	// i2b2C
	i2b2Client i2b2.Client

}

func (ds I2b2DataSource) Init(dm *datamanager.DataManager, logger *logrus.Logger, config map[string]string) error {
	ds.dm = dm

	fmt.Println("called init")
	return nil
}

func (ds I2b2DataSource) Query(userID string, operation string, parameters map[string]interface{}, resultsSharedIds map[string]string) (results map[string]interface{}, err error) {
	fmt.Println("called query")
	return nil, nil
}
