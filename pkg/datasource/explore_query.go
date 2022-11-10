package datasource

import (
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/models"
	i2b2clientmodels "github.com/tuneinsight/geco-i2b2-data-source/pkg/i2b2client/models"
	gecomodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk"
	gecosdk "github.com/tuneinsight/sdk-datasource/pkg/sdk"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk/telemetry"
	"go.opentelemetry.io/otel/trace"
)

// Names of output data objects.
const (
	outputNameExploreQueryCount       sdk.OutputDataObjectName = "count"
	outputNameExploreQueryPatientList sdk.OutputDataObjectName = "patientList"
)

// ExploreQueryHandler is the OperationHandler for the OperationExploreQuery Operation.
func (ds *I2b2DataSource) ExploreQueryHandler(userID string, jsonParameters []byte, outputDataObjectsSharedIDs map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID) (jsonResults []byte, outputDataObjects []gecosdk.DataObject, err error) {

	span := telemetry.StartSpan(ds.Ctx, "datasource:i2b2", "ExploreQueryHandler", trace.WithNewRoot())
	defer span.End()

	// parse parameters
	decodedParams := &models.ExploreQueryParameters{}
	if outputDataObjectsSharedIDs[outputNameExploreQueryCount] == "" || outputDataObjectsSharedIDs[outputNameExploreQueryPatientList] == "" {
		return nil, nil, fmt.Errorf("missing output data object name")
	} else if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("decoding parameters: %v", err)
	}

	// register query in DB
	if queryDef, err := json.Marshal(decodedParams.Definition); err != nil {
		return nil, nil, fmt.Errorf("marshalling query definition: %v", err)
	} else if err := ds.db.AddExploreQuery(userID, decodedParams.ID, string(queryDef)); err != nil {
		return nil, nil, fmt.Errorf("registering explore query: %v", err)
	} else if err := ds.db.SetExploreQueryRunning(userID, decodedParams.ID); err != nil {
		return nil, nil, fmt.Errorf("updating explore query status: %v", err)
	}

	// run query and update status in DB
	i2b2PatientSetID, count, patientList, err := ds.ExploreQuery(userID, decodedParams)
	if err != nil {
		return nil, nil, fmt.Errorf("executing query: %v", err)
	} else if err := ds.db.SetExploreQuerySuccess(
		userID, decodedParams.ID, i2b2PatientSetID,
		string(outputDataObjectsSharedIDs[outputNameExploreQueryCount]),
		string(outputDataObjectsSharedIDs[outputNameExploreQueryPatientList]),
	); err != nil {
		return nil, nil, fmt.Errorf("updating explore query status: %v", err)
	}

	// wrap results in data objects
	outputDataObjects = []gecosdk.DataObject{
		{
			OutputName: outputNameExploreQueryCount,
			SharedID:   outputDataObjectsSharedIDs[outputNameExploreQueryCount],
			Columns:    []string{"count"},
			IntValue:   &count,
		}, {
			OutputName: outputNameExploreQueryPatientList,
			SharedID:   outputDataObjectsSharedIDs[outputNameExploreQueryPatientList],
			IntVector:  patientList,
		},
	}
	return
}

// ExploreQuery makes an explore query, i.e. two i2b2 CRC queries, a PSM and a PDO query.
func (ds *I2b2DataSource) ExploreQuery(userID string, params *models.ExploreQueryParameters) (patientSetID int64, patientCount int64, patientList []int64, err error) {

	span := telemetry.StartSpan(ds.Ctx, "datasource:i2b2", "ExploreQuery")
	defer span.End()

	if i2b2PatientCount, i2b2PatientSetID, err := ds.doCrcPsmQuery(userID, *params); err != nil {
		return -1, -1, nil, err
	} else if patientCount, err = strconv.ParseInt(i2b2PatientCount, 10, 64); err != nil {
		return -1, -1, nil, fmt.Errorf("parsing patient count: %v", err)
	} else if patientSetID, err = strconv.ParseInt(i2b2PatientSetID, 10, 64); err != nil {
		return -1, -1, nil, fmt.Errorf("parsing patient set ID: %v", err)
	} else if i2b2PatientIDs, err := ds.getPatientIDs(i2b2PatientSetID); err != nil {
		return -1, -1, nil, err
	} else {
		// parse patient IDs
		patientList = make([]int64, 0)
		for _, patientID := range i2b2PatientIDs {
			parsedPatientID, err := strconv.ParseInt(patientID, 10, 64)
			if err != nil {
				return -1, -1, nil, fmt.Errorf("parsing patient ID: %v", err)
			}
			patientList = append(patientList, parsedPatientID)
		}
	}
	return
}

// doCrcPsmQuery requests a PSM query to the i2b2 CRC and parse its results.
func (ds *I2b2DataSource) doCrcPsmQuery(userID string, params models.ExploreQueryParameters) (patientCount, patientSetID string, err error) {

	span := telemetry.StartSpan(ds.Ctx, "datasource:i2b2", "doCrcPsmQuery")
	defer span.End()

	// retrieve patient set IDs for cohort items and replace them in the panels
	for _, panel := range params.Definition.SelectionPanels {
		for i, cohortItem := range panel.CohortItems {
			cohort, err := ds.db.GetCohort(userID, cohortItem)
			if err != nil || cohort == nil {
				return "", "", fmt.Errorf("while getting cohort for doCrcPsmQuery: %v", err)
			}
			panel.CohortItems[i] = "patient_set_coll_id:" + strconv.FormatInt(cohort.ExploreQuery.ResultI2b2PatientSetID.Int64, 10)
		}
	}

	// build query
	panels, subQueries, subQueriesConstraints, timing, err := params.Definition.ToI2b2APIModel()
	if err != nil {
		return "", "", fmt.Errorf("while converting explore query definition to i2b2 model: %v", err)
	}

	psmReq := i2b2clientmodels.NewCrcPsmReqFromQueryDef(
		ds.i2b2Client.Ci,
		params.ID,
		panels,
		timing,
		subQueries,
		subQueriesConstraints,
		[]i2b2clientmodels.ResultOutputName{i2b2clientmodels.ResultOutputPatientSet, i2b2clientmodels.ResultOutputCount},
	)

	var psmResp *i2b2clientmodels.CrcPsmRespMessageBody
	if psmResp, err = ds.i2b2Client.CrcPsmReqFromQueryDef(&psmReq); err != nil {
		return "", "", fmt.Errorf("requesting PSM query: %v", err)
	}

	subSpan := telemetry.StartSpan(ds.Ctx, "datasource:i2b2", "doCrcPsmQuery:extractResult")
	defer subSpan.End()
	// extract results from result instances
	for i, qri := range psmResp.Response.QueryResultInstances {

		// check status
		if err := qri.CheckStatus(); err != nil {
			return "", "", fmt.Errorf("found error in query result instance %v: %v", i, err)
		}

		// extract result
		switch qri.QueryResultType.Name {
		case string(i2b2clientmodels.ResultOutputPatientSet):
			if patientSetID != "" {
				ds.logger.Warnf("unexpected additional patient set result in i2b2 CRC PSM response (previous: %v)", patientSetID)
			}
			patientSetID = qri.ResultInstanceID

		case string(i2b2clientmodels.ResultOutputCount):
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
func (ds *I2b2DataSource) getPatientIDs(patientSetID string) (patientIDs []string, err error) {

	span := telemetry.StartSpan(ds.Ctx, "datasource:i2b2", "getPatientIDs")
	defer span.End()

	pdoReq := i2b2clientmodels.NewCrcPdoReqFromInputList(patientSetID)
	var pdoResp *i2b2clientmodels.CrcPdoRespMessageBody

	if pdoResp, err = ds.i2b2Client.CrcPdoReqFromInputList(&pdoReq); err != nil {
		return nil, fmt.Errorf("requesting PDO query: %v", err)
	}

	for _, patient := range pdoResp.Response.PatientData.PatientSet.Patient {
		patientIDs = append(patientIDs, patient.PatientID)
	}
	return
}
