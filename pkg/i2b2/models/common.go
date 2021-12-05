package models

import (
	"encoding/xml"
	"errors"
	"strconv"
	"time"
)

// ConnectionInfo contains the data needed for connection to i2b2.
type ConnectionInfo struct {

	// HiveURL is the URL of the i2b2 hive
	HiveURL string

	// Domain is the i2b2 login domain
	Domain string

	// Username is the i2b2 login username
	Username string

	// Password is the i2b2 login password
	Password string

	// Project is the i2b2 project ID
	Project string

	// WaitTime is the wait time to send with i2b2 requests
	WaitTime time.Duration
}

// NewRequest creates a new ready-to-use i2b2 request, with a nil message body.
func NewRequest(ci ConnectionInfo) Request {
	now := time.Now()
	return Request{
		XMLNSMSG:    "http://www.i2b2.org/xsd/hive/msg/1.1/",
		XMLNSONT:    "http://www.i2b2.org/xsd/cell/ont/1.1/",
		XMLNSPDO:    "http://www.i2b2.org/xsd/hive/pdo/1.1/",
		XMLNSCRCPDO: "http://www.i2b2.org/xsd/cell/crc/pdo/1.1/",
		XMLNSCRCPSM: "http://www.i2b2.org/xsd/cell/crc/psm/1.1/",

		MessageHeader: MessageHeader{
			I2b2VersionCompatible:                  "0.3",
			Hl7VersionCompatible:                   "2.4",
			SendingApplicationApplicationName:      "GeCo i2b2 Data Source",
			SendingApplicationApplicationVersion:   "0.2",
			SendingFacilityFacilityName:            "GeCo",
			ReceivingApplicationApplicationName:    "i2b2 cell",
			ReceivingApplicationApplicationVersion: "1.7",
			ReceivingFacilityFacilityName:          "i2b2 hive",
			DatetimeOfMessage:                      now.Format(time.RFC3339),
			SecurityDomain:                         ci.Domain,
			SecurityUsername:                       ci.Username,
			SecurityPassword:                       ci.Password,
			MessageTypeMessageCode:                 "EQQ",
			MessageTypeEventType:                   "Q04",
			MessageTypeMessageStructure:            "EQQ_Q04",
			MessageControlIDSessionID:              now.Format(time.RFC3339),
			MessageControlIDMessageNum:             strconv.FormatInt(now.Unix(), 10),
			MessageControlIDInstanceNum:            "0",
			ProcessingIDProcessingID:               "P",
			ProcessingIDProcessingMode:             "I",
			AcceptAcknowledgementType:              "messageId",
			ApplicationAcknowledgementType:         "",
			CountryCode:                            "CH",
			ProjectID:                              ci.Project,
		},
		RequestHeader: RequestHeader{
			ResultWaittimeMs: strconv.FormatInt(ci.WaitTime.Milliseconds(), 10),
		},
	}
}

// NewRequestWithBody creates a new ready-to-use i2b2 request, with a message body
func NewRequestWithBody(ci ConnectionInfo, body MessageBody) (req Request) {
	req = NewRequest(ci)
	req.MessageBody = body
	return
}

// Request is an i2b2 XML request
type Request struct {
	XMLName     xml.Name `xml:"msgns:request"`
	XMLNSMSG    string   `xml:"xmlns:msgns,attr"`
	XMLNSPDO    string   `xml:"xmlns:pdons,attr"`
	XMLNSONT    string   `xml:"xmlns:ontns,attr"`
	XMLNSCRCPDO string   `xml:"xmlns:crcpdons,attr"`
	XMLNSCRCPSM string   `xml:"xmlns:crcpsmns,attr"`

	MessageHeader MessageHeader `xml:"message_header"`
	RequestHeader RequestHeader `xml:"request_header"`
	MessageBody   MessageBody   `xml:"message_body"`
}

// Response is an i2b2 XML response
type Response struct {
	XMLName        xml.Name       `xml:"response"`
	MessageHeader  MessageHeader  `xml:"message_header"`
	RequestHeader  RequestHeader  `xml:"request_header"`
	ResponseHeader ResponseHeader `xml:"response_header"`
	MessageBody    MessageBody    `xml:"message_body"`
}

func (response *Response) CheckStatus() error {
	if response.ResponseHeader.ResultStatus.Status.Type != "DONE" {
		return errors.New(response.ResponseHeader.ResultStatus.Status.Text)
	}
	return nil
}

// MessageHeader is an i2b2 XML header embedded in a request or response
type MessageHeader struct {
	XMLName xml.Name `xml:"message_header"`

	I2b2VersionCompatible string `xml:"i2b2_version_compatible"`
	Hl7VersionCompatible  string `xml:"hl7_version_compatible"`

	SendingApplicationApplicationName    string `xml:"sending_application>application_name"`
	SendingApplicationApplicationVersion string `xml:"sending_application>application_version"`

	SendingFacilityFacilityName string `xml:"sending_facility>facility_name"`

	ReceivingApplicationApplicationName    string `xml:"receiving_application>application_name"`
	ReceivingApplicationApplicationVersion string `xml:"receiving_application>application_version"`

	ReceivingFacilityFacilityName string `xml:"receiving_facility>facility_name"`

	DatetimeOfMessage string `xml:"datetime_of_message"`

	SecurityDomain   string `xml:"security>domain"`
	SecurityUsername string `xml:"security>username"`
	SecurityPassword string `xml:"security>password"`

	MessageTypeMessageCode      string `xml:"message_type>message_code"`
	MessageTypeEventType        string `xml:"message_type>event_type"`
	MessageTypeMessageStructure string `xml:"message_type>message_structure"`

	MessageControlIDSessionID   string `xml:"message_control_id>session_id"`
	MessageControlIDMessageNum  string `xml:"message_control_id>message_num"`
	MessageControlIDInstanceNum string `xml:"message_control_id>instance_num"`

	ProcessingIDProcessingID   string `xml:"processing_id>processing_id"`
	ProcessingIDProcessingMode string `xml:"processing_id>processing_mode"`

	AcceptAcknowledgementType      string `xml:"accept_acknowledgement_type"`
	ApplicationAcknowledgementType string `xml:"application_acknowledgement_type"`
	CountryCode                    string `xml:"country_code"`
	ProjectID                      string `xml:"project_id"`
}

// RequestHeader is an i2b2 XML header embedded in a request
type RequestHeader struct {
	XMLName          xml.Name `xml:"request_header"`
	ResultWaittimeMs string   `xml:"result_waittime_ms"`
}

// ResponseHeader is an i2b2 XML header embedded in a response
type ResponseHeader struct {
	XMLName xml.Name `xml:"response_header"`
	Info    struct {
		Text string `xml:",chardata"`
		URL  string `xml:"url,attr"`
	} `xml:"info"`
	ResultStatus struct {
		Status struct {
			Text string `xml:",chardata"`
			Type string `xml:"type,attr"`
		} `xml:"status"`
		PollingURL struct {
			Text       string `xml:",chardata"`
			IntervalMs string `xml:"interval_ms,attr"`
		} `xml:"polling_url"`
		Conditions struct {
			Condition []struct {
				Text         string `xml:",chardata"`
				Type         string `xml:"type,attr"`
				CodingSystem string `xml:"coding_system,attr"`
			} `xml:"condition"`
		} `xml:"conditions"`
	} `xml:"result_status"`
}

// MessageBody is an i2b2 XML generic body
type MessageBody interface{}
