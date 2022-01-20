package i2b2client

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2client/models"
	"github.com/sirupsen/logrus"
)

// Client is an i2b2 client for its XML API.
type Client struct {

	// Logger is the Logger from GeCo
	Logger logrus.FieldLogger

	// Ci contains the connection information to the i2b2 instance
	Ci models.ConnectionInfo
}

// xmlRequest makes an HTTP POST request with an XML payload to i2b2.
func (c Client) xmlRequest(endpoint string, xmlRequest *models.Request, xmlResponse *models.Response) error {
	reqURL := c.Ci.HiveURL + endpoint
	c.Logger.Infof("i2b2 XML request to %v", reqURL)

	xmlRequest.SetConnectionInfo(c.Ci)

	// marshal request
	marshaledRequest, err := xml.MarshalIndent(xmlRequest, "  ", "    ")
	if err != nil {
		return fmt.Errorf("marshalling i2b2 request marshalling: %v", err)
	}
	marshaledRequest = append([]byte(xml.Header), marshaledRequest...)
	c.Logger.Debugf("i2b2 request:\n%v", string(marshaledRequest))

	// execute HTTP request
	httpResponse, err := http.Post(reqURL, "application/xml", bytes.NewBuffer(marshaledRequest))
	if err != nil {
		return fmt.Errorf("making HTTP POST of XML request: %v", err)
	}
	defer httpResponse.Body.Close()

	// unmarshal response
	httpBody, err := ioutil.ReadAll(httpResponse.Body)
	if err != nil {
		return fmt.Errorf("reading XML response: %v", err)
	}
	c.Logger.Debugf("i2b2 response:\n%v", string(httpBody))

	if err := xml.Unmarshal(httpBody, xmlResponse); err != nil {
		return fmt.Errorf("unmarshalling XML response: %v", err)
	}

	// check i2b2 request status
	if err := xmlResponse.CheckStatus(); err != nil {
		return fmt.Errorf("found error in i2b2 response: %v", err)
	}
	return nil
}
