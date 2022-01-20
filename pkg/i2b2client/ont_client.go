package i2b2client

import (
	"fmt"

	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2client/models"
)

// OntGetCategories makes an i2b2 API request to /OntologyService/getCategories.
func (c Client) OntGetCategories(reqMsgBody *models.OntReqGetCategoriesMessageBody) (*models.OntRespConceptsMessageBody, error) {
	return c.ontConceptsRequest("/OntologyService/getCategories", reqMsgBody)
}

// OntGetChildren makes an i2b2 API request to /OntologyService/getChildren.
func (c Client) OntGetChildren(reqMsgBody *models.OntReqGetChildrenMessageBody) (*models.OntRespConceptsMessageBody, error) {
	return c.ontConceptsRequest("/OntologyService/getChildren", reqMsgBody)
}

// OntGetTermInfo makes an i2b2 API request to /OntologyService/getTermInfo.
func (c Client) OntGetTermInfo(reqMsgBody *models.OntReqGetTermInfoMessageBody) (*models.OntRespConceptsMessageBody, error) {
	return c.ontConceptsRequest("/OntologyService/getTermInfo", reqMsgBody)
}

// ontConceptsRequest makes an i2b2 API request to a service under /OntologyService/ returning a models.OntRespConceptsMessageBody.
func (c Client) ontConceptsRequest(endpoint string, reqMsgBody models.MessageBody) (*models.OntRespConceptsMessageBody, error) {
	xmlRequest := models.NewRequestWithBody(reqMsgBody)
	xmlResponse := &models.Response{
		MessageBody: &models.OntRespConceptsMessageBody{},
	}

	if err := c.xmlRequest(endpoint, &xmlRequest, xmlResponse); err != nil {
		return nil, fmt.Errorf("making XML request: %v", err)
	}

	mb, ok := xmlResponse.MessageBody.(*models.OntRespConceptsMessageBody)
	if !ok {
		return nil, fmt.Errorf("casting message body, got %T", xmlResponse.MessageBody)
	}
	return mb, nil
}

// OntGetModifiers makes an i2b2 API request to /OntologyService/getModifiers.
func (c Client) OntGetModifiers(reqMsgBody *models.OntReqGetModifiersMessageBody) (*models.OntRespModifiersMessageBody, error) {
	return c.ontModifiersRequest("/OntologyService/getModifiers", reqMsgBody)
}

// OntGetModifierChildren makes an i2b2 API request to /OntologyService/getModifierChildren.
func (c Client) OntGetModifierChildren(reqMsgBody *models.OntReqGetModifierChildrenMessageBody) (*models.OntRespModifiersMessageBody, error) {
	return c.ontModifiersRequest("/OntologyService/getModifierChildren", reqMsgBody)
}

// OntGetModifierInfo makes an i2b2 API request to /OntologyService/getModifierInfo.
func (c Client) OntGetModifierInfo(reqMsgBody *models.OntReqGetModifierInfoMessageBody) (*models.OntRespModifiersMessageBody, error) {
	return c.ontModifiersRequest("/OntologyService/getModifierInfo", reqMsgBody)
}

// ontModifiersRequest makes an i2b2 API request to a service under /OntologyService/ returning a models.OntRespModifiersMessageBody.
func (c Client) ontModifiersRequest(endpoint string, reqMsgBody models.MessageBody) (*models.OntRespModifiersMessageBody, error) {
	xmlRequest := models.NewRequestWithBody(reqMsgBody)
	xmlResponse := &models.Response{
		MessageBody: &models.OntRespModifiersMessageBody{},
	}

	if err := c.xmlRequest(endpoint, &xmlRequest, xmlResponse); err != nil {
		return nil, fmt.Errorf("making XML request: %v", err)
	}

	mb, ok := xmlResponse.MessageBody.(*models.OntRespModifiersMessageBody)
	if !ok {
		return nil, fmt.Errorf("casting message body, got %T", xmlResponse.MessageBody)
	}
	return mb, nil
}
