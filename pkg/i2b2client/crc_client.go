package i2b2client

import (
	"fmt"

	"github.com/tuneinsight/geco-i2b2-data-source/pkg/i2b2client/models"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk/telemetry"
)

// CrcPsmReqFromQueryDef makes an i2b2 API request to /QueryToolService/request for CRC PSM from query definition.
func (c Client) CrcPsmReqFromQueryDef(reqMsgBody *models.CrcPsmReqFromQueryDefMessageBody) (*models.CrcPsmRespMessageBody, error) {

	span := telemetry.StartSpan(&c.Ctx, "datasource:i2b2", "doCrcPsmQuery:CrcPsmReqFromQueryDef")
	defer span.End()

	xmlRequest := models.NewRequestWithBody(reqMsgBody)
	xmlResponse := &models.Response{
		MessageBody: &models.CrcPsmRespMessageBody{},
	}

	if err := c.xmlRequest("/QueryToolService/request", &xmlRequest, xmlResponse); err != nil {
		return nil, fmt.Errorf("making XML request: %v", err)
	}

	if mb, ok := xmlResponse.MessageBody.(*models.CrcPsmRespMessageBody); !ok {
		return nil, fmt.Errorf("casting message body, got %T", xmlResponse.MessageBody)
	} else if err := mb.CheckStatus(); err != nil {
		return nil, fmt.Errorf("found error in i2b2 CRC PSM response: %v", err)
	} else {
		return mb, nil
	}
}

// CrcPdoReqFromInputList makes an i2b2 API request to /QueryToolService/pdorequest for CRC PDO from input list.
func (c Client) CrcPdoReqFromInputList(reqMsgBody *models.CrcPdoReqFromInputListMessageBody) (*models.CrcPdoRespMessageBody, error) {

	span := telemetry.StartSpan(&c.Ctx, "datasource:i2b2", "getPatientIDs:CrcPdoReqFromInputList")
	defer span.End()

	xmlRequest := models.NewRequestWithBody(reqMsgBody)
	xmlResponse := &models.Response{
		MessageBody: &models.CrcPdoRespMessageBody{},
	}

	if err := c.xmlRequest("/QueryToolService/pdorequest", &xmlRequest, xmlResponse); err != nil {
		return nil, fmt.Errorf("making XML request: %v", err)
	}

	mb, ok := xmlResponse.MessageBody.(*models.CrcPdoRespMessageBody)
	if !ok {
		return nil, fmt.Errorf("casting message body, got %T", xmlResponse.MessageBody)
	}
	return mb, nil
}
