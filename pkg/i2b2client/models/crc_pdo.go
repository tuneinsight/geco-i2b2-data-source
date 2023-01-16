package models

import (
	"encoding/xml"
)

// --- request

// NewCrcPdoReqFromInputList returns a new request object for i2b2 pdo request.
func NewCrcPdoReqFromInputList(patientSetID string) CrcPdoReqFromInputListMessageBody {

	// PDO header
	pdoHeader := PdoHeader{
		PatientSetLimit: "0",
		EstimatedTime:   "0",
		RequestType:     "getPDO_fromInputList",
	}

	// PDO request
	pdoRequest := PdoRequestFromInputList{
		Type: "crcpdons:GetPDOFromInputList_requestType",
		Xsi:  "http://www.w3.org/2001/XMLSchema-instance",
	}

	// set request for patient set ID
	pdoRequest.InputList.PatientList.Max = "1000000"
	pdoRequest.InputList.PatientList.Min = "0"
	pdoRequest.InputList.PatientList.PatientSetCollID = patientSetID
	pdoRequest.OutputOption.Name = "none"

	pdoRequest.OutputOption.PatientSet = &OutputOptionItem{
		Blob:     "false",
		TechData: "false",
		OnlyKeys: "true",
		Select:   "using_input_list",
	}

	pdoRequest.OutputOption.ObservationSet = &OutputOptionItem{
		Blob:     "false",
		TechData: "false",
		OnlyKeys: "false",
		Select:   "using_input_list",
	}

	return CrcPdoReqFromInputListMessageBody{
		PdoHeader:  pdoHeader,
		PdoRequest: pdoRequest,
	}
}

// CrcPdoReqFromInputListMessageBody is an i2b2 XML message body for CRC PDO request from input list.
type CrcPdoReqFromInputListMessageBody struct {
	XMLName xml.Name `xml:"message_body"`

	PdoHeader  PdoHeader               `xml:"crcpdons:pdoheader"`
	PdoRequest PdoRequestFromInputList `xml:"crcpdons:request"`
}

// PdoHeader is an i2b2 XML header for PDO requests.
type PdoHeader struct {
	PatientSetLimit string `xml:"patient_set_limit"`
	EstimatedTime   string `xml:"estimated_time"`
	RequestType     string `xml:"request_type"`
}

// OutputOptionItem is an item of OutputOption
type OutputOptionItem struct {
	Select          string `xml:"select,attr"`
	OnlyKeys        string `xml:"onlykeys,attr"`
	Blob            string `xml:"blob,attr"`
	TechData        string `xml:"techdata,attr"`
	SelectionFilter string `xml:"selection_filter,attr"`
}

// PdoRequestFromInputList is an i2b2 XML PDO request - from input list.
type PdoRequestFromInputList struct {
	Type string `xml:"xsi:type,attr"`
	Xsi  string `xml:"xmlns:xsi,attr"`

	InputList struct {
		PatientList struct {
			Max              string `xml:"max,attr"`
			Min              string `xml:"min,attr"`
			PatientSetCollID string `xml:"patient_set_coll_id"`
		} `xml:"patient_list,omitempty"`
	} `xml:"input_list"`

	FilterList struct {
		Panel []Panel `xml:"panel"`
	} `xml:"filter_list"`

	OutputOption struct {
		Name           string            `xml:"name,attr"`
		PatientSet     *OutputOptionItem `xml:"patient_set,omitempty"`
		ObservationSet *OutputOptionItem `xml:"observation_set,omitempty"`
	} `xml:"output_option"`
}

// --- response

// CrcPdoRespMessageBody is an i2b2 XML message body for CRC PDO response.
type CrcPdoRespMessageBody struct {
	XMLName xml.Name `xml:"message_body"`

	Response struct {
		Xsi         string `xml:"xsi,attr"`
		Type        string `xml:"type,attr"`
		PatientData struct {
			PatientSet struct {
				Patient []struct {
					PatientID string `xml:"patient_id"`
					Param     []struct {
						Text             string `xml:",chardata"`
						Type             string `xml:"type,attr"`
						ColumnDescriptor string `xml:"column_descriptor,attr"`
						Column           string `xml:"column,attr"`
					} `xml:"param"`
				} `xml:"patient"`
			} `xml:"patient_set,omitempty"`
			ObservationSet []struct {
				PanelName   string `xml:"panel_name,attr"`
				Observation []struct {
					EventID struct {
						Text   string `xml:",chardata"`
						Source string `xml:"source,attr"`
					} `xml:"event_id"`
					PatientID string `xml:"patient_id"`
					ConceptCd struct {
						Text string `xml:",chardata"`
						Name string `xml:"name,attr"`
					} `xml:"concept_cd"`
					ObserverCd struct {
						Text   string `xml:",chardata"`
						Source string `xml:"source,attr"`
					} `xml:"observer_cd"`
					StartDate  string `xml:"start_date"`
					ModifierCd struct {
						Text string `xml:",chardata"`
						Name string `xml:"name,attr"`
					} `xml:"modifier_cd"`
					InstanceNum string `xml:"instance_num"`
					ValueTypeCd string `xml:"valuetype_cd"`
					TvalChar    string `xml:"tval_char"`
					NvalNum     struct {
						Text  string `xml:",chardata"`
						Units string `xml:"units,attr"`
					} `xml:"nval_num"`
					ValueflagCD struct {
						Text string `xml:",chardata"`
						Name string `xml:"name,attr"`
					} `xml:"valueflag_cd"`
					QuantityNum string `xml:"quantity_num"`
					UnitsCd     string `xml:"units_cd"`
					EndDate     string `xml:"end_date"`
					LocationCD  struct {
						Text string `xml:",chardata"`
						Name string `xml:"name,attr"`
					} `xml:"location_cd"`
				} `xml:"observation"`
			} `xml:"observation_set,omitempty"`
		} `xml:"patient_data"`
	} `xml:"response"`
}
