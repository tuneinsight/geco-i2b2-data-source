package i2b2

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2/models"
	"github.com/sirupsen/logrus"
)

// todo: define API of what's needed from geco
// todo: then define the query functions that take as arguments the API models
// todo: then adapt the existing XML request to be made
// todo: add tests and integration with CI

// Client is an i2b2 client for its XML API
type Client struct {

	// logger is the logger from GeCo
	logger *logrus.Logger

	// ci contains the connection information to the i2b2 instance
	ci models.ConnectionInfo

	// ontMaxElements is the configuration for the maximum number of ontology elements to return from i2b2
	ontMaxElements string
}

// xmlRequest makes an HTTP POST request to i2b2
func (c Client) xmlRequest(endpoint string, xmlRequest interface{}, xmlResponse *models.Response) error {
	reqUrl := c.ci.HiveURL + endpoint
	c.logger.Infof("i2b2 XML request to %v", reqUrl)

	// marshal request
	marshaledRequest, err := xml.MarshalIndent(xmlRequest, "  ", "    ")
	if err != nil {
		return fmt.Errorf("marshalling i2b2 request marshalling: %v", err)
	}
	marshaledRequest = append([]byte(xml.Header), marshaledRequest...)
	c.logger.Debugf("i2b2 request:\n%v", string(marshaledRequest))

	// execute HTTP request
	httpResponse, err := http.Post(reqUrl, "application/xml", bytes.NewBuffer(marshaledRequest))
	if err != nil {
		return fmt.Errorf("making HTTP POST of XML request: %v", err)
	}
	defer httpResponse.Body.Close()

	// unmarshal response
	httpBody, err := ioutil.ReadAll(httpResponse.Body)
	if err != nil {
		return fmt.Errorf("reading XML response: %v", err)
	}
	c.logger.Debugf("i2b2 response:\n%v", string(httpBody))

	if err := xml.Unmarshal(httpBody, xmlResponse); err != nil {
		return fmt.Errorf("unmarshalling XML response: %v", err)
	}

	// check i2b2 request status
	if err := xmlResponse.CheckStatus(); err != nil {
		return fmt.Errorf("found error in i2b2 response: %v", err)
	}
	return nil
}
