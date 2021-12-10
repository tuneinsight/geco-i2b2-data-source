package i2b2datasource

import (
	"fmt"
	"strconv"

	i2b2apimodels "github.com/ldsec/geco-i2b2-data-source/pkg/i2b2api/models"
	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2datasource/models"
)

// ExploreQuery makes an explore query, i.e. two i2b2 CRC queries, a PSM and a PDO query.
func (ds I2b2DataSource) ExploreQuery(params *models.ExploreQueryParameters) (patientCount uint64, patientList []uint64, err error) {

	if i2b2PatientCount, i2b2PatientSetID, err := ds.doExploreQuery(params); err != nil {
		return 0, nil, err
	} else if i2b2PatientIDs, err := ds.getPatientIDs(i2b2PatientSetID); err != nil {
		return 0, nil, err
	} else if patientCount, err = strconv.ParseUint(i2b2PatientCount, 10, 64); err != nil {
		return 0, nil, fmt.Errorf("parsing patient count: %v", err)
	} else {
		for _, patientID := range i2b2PatientIDs {
			parsedPatientID, err := strconv.ParseUint(patientID, 10, 64)
			if err != nil {
				return 0, nil, fmt.Errorf("parsing patient ID: %v", err)
			}
			patientList = append(patientList, parsedPatientID)
		}
	}

	return
}

// doExploreQuery requests an explore query to the i2b2 CRC and parse its results.
func (ds I2b2DataSource) doExploreQuery(params *models.ExploreQueryParameters) (patientCount, patientSetID string, err error) {

	// build query
	panels, timing := params.Definition.ToI2b2APIModel()
	psmReq := i2b2apimodels.NewCrcPsmReqFromQueryDef(
		ds.i2b2Client.Ci,
		params.ID,
		panels,
		timing,
		[]i2b2apimodels.ResultOutputName{i2b2apimodels.ResultOutputPatientSet, i2b2apimodels.ResultOutputCount},
	)

	// request query
	var psmResp *i2b2apimodels.CrcPsmRespMessageBody
	if psmResp, err = ds.i2b2Client.CrcPsmReqFromQueryDef(&psmReq); err != nil {
		return "", "", fmt.Errorf("requesting PSM query: %v", err)
	}

	// extract results from result instances
	for i, qri := range psmResp.Response.QueryResultInstances {

		// check status
		if err := qri.CheckStatus(); err != nil {
			return "", "", fmt.Errorf("found error in query result instance %v: %v", i, err)
		}

		// extract result
		switch qri.QueryResultType.Name {
		case string(i2b2apimodels.ResultOutputPatientSet):
			if patientSetID != "" {
				ds.logger.Warnf("unexpected additional patient set result in i2b2 CRC PSM response (previous: %v)", patientSetID)
			}
			patientSetID = qri.ResultInstanceID

		case string(i2b2apimodels.ResultOutputCount):
			if patientCount != "" {
				ds.logger.Warnf("unexpected additional patient count result in i2b2 CRC PSM response (previous: %v)", patientCount)
			}
			patientCount = qri.SetSize

		default:
			ds.logger.Warnf("unexpected result in i2b2 CRC PSM response: %v", qri.QueryResultType.Name)
		}
	}

	if patientCount == "" || patientSetID == "" {
		return "", "", fmt.Errorf("missing result from i2b2 PSM response: patientCount=%v, patientSetID=%v", patientCount, patientSetID)
	}
	return
}

// getPatientIDs retrieves the list of patient IDs from the i2b2 CRC using a patient set ID.
func (ds I2b2DataSource) getPatientIDs(patientSetID string) (patientIDs []string, err error) {
	pdoReq := i2b2apimodels.NewCrcPdoReqFromInputList(patientSetID)
	var pdoResp *i2b2apimodels.CrcPdoRespMessageBody
	if pdoResp, err = ds.i2b2Client.CrcPdoReqFromInputList(&pdoReq); err != nil {
		return nil, fmt.Errorf("requesting PDO query: %v", err)
	}

	for _, patient := range pdoResp.Response.PatientData.PatientSet.Patient {
		patientIDs = append(patientIDs, patient.PatientID)
	}
	return
}
