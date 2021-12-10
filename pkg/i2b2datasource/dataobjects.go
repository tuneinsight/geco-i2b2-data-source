package i2b2datasource

import (
	"fmt"

	"github.com/ldsec/geco/pkg/datamanager"
	gecomodels "github.com/ldsec/geco/pkg/models"
)

// todo: geco data manager needs to allow data objects that are int and int vectors, it is now temporarily stored as float!

// storeIntValue stores an integer value in the data manager.
func (ds I2b2DataSource) storeIntValue(value uint64, doSharedID string) error {

	do := datamanager.NewFloatVector([]float64{float64(value)}) // todo: need to be different type of data object

	doID, err := ds.dm.AddDataObjectWithSharedID(do, gecomodels.DataObjectSharedID(doSharedID), false)
	if err != nil {
		return fmt.Errorf("adding data object: %v", err)
	}
	ds.logger.Infof("added data object to data manager (%v)", doID)

	return nil
}

// storeIntVector stores a vector of integers in the data manager.
func (ds I2b2DataSource) storeIntVector(values []uint64, doSharedID string) error {

	var floats []float64
	for _, value := range values {
		floats = append(floats, float64(value))
	}
	do := datamanager.NewFloatVector(floats) // todo: need to be different type of data object

	doID, err := ds.dm.AddDataObjectWithSharedID(do, gecomodels.DataObjectSharedID(doSharedID), false)
	if err != nil {
		return fmt.Errorf("adding data object: %v", err)
	}
	ds.logger.Infof("added data object to data manager (%v)", doID)

	return nil
}
