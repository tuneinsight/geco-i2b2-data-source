package models

import (
	"encoding/xml"
	"fmt"
	"strconv"
	"strings"
)

// --- request

// NewCrcPsmReqFromQueryDef returns a new request object for i2b2 psm request.
func NewCrcPsmReqFromQueryDef(ci ConnectionInfo, queryName string, queryPanels []Panel, queryTiming Timing,
	resultOutputs []ResultOutputName) CrcPsmReqFromQueryDefMessageBody {

	// PSM header
	psmHeader := PsmHeader{
		PatientSetLimit: "0",
		EstimatedTime:   "0",
		QueryMode:       "optimize_without_temp_table",
		RequestType:     "CRC_QRY_runQueryInstance_fromQueryDefinition",
	}
	psmHeader.User.Text = ci.Username
	psmHeader.User.Group = ci.Domain
	psmHeader.User.Login = ci.Username

	// PSM request
	psmRequest := PsmRequestFromQueryDef{
		Type: "crcpsmns:query_definition_requestType",
		Xsi:  "http://www.w3.org/2001/XMLSchema-instance",

		QueryName:        queryName,
		QueryID:          queryName,
		QueryDescription: "Query from GeCo i2b2 data source (" + queryName + ")",
		QueryTiming:      string(queryTiming),
		SpecificityScale: "0",
		Panels:           queryPanels,
	}

	// embed result outputs
	for i, resultOutput := range resultOutputs {
		psmRequest.ResultOutputs = append(psmRequest.ResultOutputs, ResultOutput{
			PriorityIndex: strconv.Itoa(i + 1),
			Name:          string(resultOutput),
		})
	}

	return CrcPsmReqFromQueryDefMessageBody{
		PsmHeader:  psmHeader,
		PsmRequest: psmRequest,
	}
}

// CrcPsmReqFromQueryDefMessageBody is an i2b2 XML message body for CRC PSM request from query definition.
type CrcPsmReqFromQueryDefMessageBody struct {
	XMLName xml.Name `xml:"message_body"`

	PsmHeader  PsmHeader              `xml:"crcpsmns:psmheader"`
	PsmRequest PsmRequestFromQueryDef `xml:"crcpsmns:request"`
}

// PsmHeader is an i2b2 XML header for PSM request.
type PsmHeader struct {
	User struct {
		Text  string `xml:",chardata"`
		Group string `xml:"group,attr"`
		Login string `xml:"login,attr"`
	} `xml:"user"`

	PatientSetLimit string `xml:"patient_set_limit"`
	EstimatedTime   string `xml:"estimated_time"`
	QueryMode       string `xml:"query_mode"`
	RequestType     string `xml:"request_type"`
}

// PsmRequestFromQueryDef is an i2b2 XML PSM request from query definition.
type PsmRequestFromQueryDef struct {
	Type string `xml:"xsi:type,attr"`
	Xsi  string `xml:"xmlns:xsi,attr"`

	QueryName        string  `xml:"query_definition>query_name"`
	QueryDescription string  `xml:"query_definition>query_description"`
	QueryID          string  `xml:"query_definition>query_id"`
	QueryTiming      string  `xml:"query_definition>query_timing"`
	SpecificityScale string  `xml:"query_definition>specificity_scale"`
	Panels           []Panel `xml:"query_definition>panel"`

	ResultOutputs []ResultOutput `xml:"result_output_list>result_output"`
}

// NewPanel creates a new Panel.
func NewPanel(panelNb int, not bool, timing Timing, items []Item) Panel {
	invert := "0"
	if not {
		invert = "1"
	}

	return Panel{
		PanelNumber:          strconv.Itoa(panelNb + 1),
		PanelAccuracyScale:   "100",
		Invert:               invert,
		Items:                items,
		PanelTiming:          string(timing),
		TotalItemOccurrences: "1",
	}
}

// Panel is an i2b2 XML panel.
type Panel struct {
	PanelNumber          string `xml:"panel_number"`
	PanelAccuracyScale   string `xml:"panel_accuracy_scale"`
	Invert               string `xml:"invert"`
	PanelTiming          string `xml:"panel_timing"`
	TotalItemOccurrences string `xml:"total_item_occurrences"`

	Items []Item `xml:"item"`
}

// Item is an i2b2 XML item.
type Item struct {
	Hlevel              string               `xml:"hlevel"`
	ItemName            string               `xml:"item_name"`
	ItemKey             string               `xml:"item_key"`
	Tooltip             string               `xml:"tooltip"`
	Class               string               `xml:"class"`
	ConstrainByValue    *ConstrainByValue    `xml:"constrain_by_value,omitempty"`
	ConstrainByModifier *ConstrainByModifier `xml:"constrain_by_modifier,omitempty"`
	ItemIcon            string               `xml:"item_icon"`
	ItemIsSynonym       string               `xml:"item_is_synonym"`
}

// ConstrainByModifier is an i2b2 XML constrain_by_modifier element.
type ConstrainByModifier struct {
	AppliedPath      string            `xml:"applied_path"`
	ModifierKey      string            `xml:"modifier_key"`
	ConstrainByValue *ConstrainByValue `xml:"constrain_by_value"`
}

// ConstrainByValue is an i2b2 XML constrain_by_value element.
type ConstrainByValue struct {
	ValueType       string `xml:"value_type"`
	ValueOperator   string `xml:"value_operator"`
	ValueConstraint string `xml:"value_constraint"`
}

// ResultOutput is an i2b2 XML requested result type.
type ResultOutput struct {
	PriorityIndex string `xml:"priority_index,attr"`
	Name          string `xml:"name,attr"`
}

// ResultOutputName is an i2b2 XML requested result type value.
type ResultOutputName string

// Enumerated values for ResultOutputName.
const (
	ResultOutputPatientSet       ResultOutputName = "PATIENTSET"
	ResultOutputEncounterSet     ResultOutputName = "PATIENT_ENCOUNTER_SET"
	ResultOutputCount            ResultOutputName = "PATIENT_COUNT_XML"
	ResultOutputGenderCount      ResultOutputName = "PATIENT_GENDER_COUNT_XML"
	ResultOutputAgeCount         ResultOutputName = "PATIENT_AGE_COUNT_XML"
	ResultOutputVitalStatusCount ResultOutputName = "PATIENT_VITALSTATUS_COUNT_XML"
	ResultOutputRaceCount        ResultOutputName = "PATIENT_RACE_COUNT_XML"
)

// Timing is an i2b2 XML timing.
type Timing string

// Enumerated values for Timing.
const (
	TimingAny             Timing = "ANY"
	TimingSameVisit       Timing = "SAMEVISIT"
	TimingSameInstanceNum Timing = "SAMEINSTANCENUM"
)

// --- response

// CrcPsmRespMessageBody is an i2b2 XML message body for CRC PSM response
type CrcPsmRespMessageBody struct {
	XMLName xml.Name `xml:"message_body"`

	Response struct {
		Type string `xml:"type,attr"`

		Status []struct {
			Text string `xml:",chardata"`
			Type string `xml:"type,attr"`
		} `xml:"status>condition"`

		QueryMasters []struct {
			QueryMasterID string `xml:"query_master_id"`
			Name          string `xml:"name"`
			UserID        string `xml:"user_id"`
			GroupID       string `xml:"group_id"`
			CreateDate    string `xml:"create_date"`
			DeleteDate    string `xml:"delete_date"`
			RequestXML    string `xml:"request_xml"`
			GeneratedSQL  string `xml:"generated_sql"`
		} `xml:"query_master"`

		QueryInstances []struct {
			QueryInstanceID string `xml:"query_instance_id"`
			QueryMasterID   string `xml:"query_master_id"`
			UserID          string `xml:"user_id"`
			GroupID         string `xml:"group_id"`
			BatchMode       string `xml:"batch_mode"`
			StartDate       string `xml:"start_date"`
			EndDate         string `xml:"end_date"`
			QueryStatusType struct {
				StatusTypeID string `xml:"status_type_id"`
				Name         string `xml:"name"`
				Description  string `xml:"description"`
			} `xml:"query_status_type"`
		} `xml:"query_instance"`

		QueryResultInstances []QueryResultInstance `xml:"query_result_instance"`
	} `xml:"response"`
}

// CheckStatus returns an error if the status of the CrcPsmRespMessageBody is not successful.
func (mb CrcPsmRespMessageBody) CheckStatus() error {
	var errorMessages []string
	for _, status := range mb.Response.Status {
		if status.Type == "ERROR" || status.Type == "FATAL_ERROR" {
			errorMessages = append(errorMessages, status.Text)
		}
	}

	if len(errorMessages) != 0 {
		return fmt.Errorf(strings.Join(errorMessages, "; "))
	}
	return nil
}

// QueryResultInstance is an i2b2 XML query result instance.
type QueryResultInstance struct {
	ResultInstanceID string `xml:"result_instance_id"`
	QueryInstanceID  string `xml:"query_instance_id"`
	QueryResultType  struct {
		ResultTypeID string `xml:"result_type_id"`
		Name         string `xml:"name"`
		Description  string `xml:"description"`
	} `xml:"query_result_type"`
	SetSize         string `xml:"set_size"`
	StartDate       string `xml:"start_date"`
	EndDate         string `xml:"end_date"`
	QueryStatusType struct {
		StatusTypeID string `xml:"status_type_id"`
		Name         string `xml:"name"`
		Description  string `xml:"description"`
	} `xml:"query_status_type"`
}

// CheckStatus returns an error if the status of the QueryResultInstance is not successful.
func (qri QueryResultInstance) CheckStatus() error {
	if qri.QueryStatusType.StatusTypeID != "3" {
		return fmt.Errorf("i2b2 result instance does not have finished status: %v / %v / %v", qri.QueryStatusType.StatusTypeID, qri.QueryStatusType.Name, qri.QueryStatusType.Description)
	}
	return nil
}
