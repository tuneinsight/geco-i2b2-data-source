package i2b2client

import (
	"bytes"
	"context"
	"encoding/xml"
	"fmt"
	"io"

	"github.com/sirupsen/logrus"
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/i2b2client/models"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk/telemetry"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel/attribute"
)

// Client is an i2b2 client for its XML API.
type Client struct {

	// CTx is the context to Telemetry
	Ctx context.Context

	// Logger is the Logger from GeCo
	Logger logrus.FieldLogger

	// Ci contains the connection information to the i2b2 instance
	Ci models.ConnectionInfo
}

// xmlRequest makes an HTTP POST request with an XML payload to i2b2.
func (c Client) xmlRequest(endpoint string, xmlRequest *models.Request, xmlResponse *models.Response) error {

	span := telemetry.StartSpan(&c.Ctx, "i2b2client", "xmlRequest")
	defer span.End()

	reqURL := c.Ci.HiveURL + endpoint
	c.Logger.Infof("i2b2 XML request to %v", reqURL)

	xmlRequest.SetConnectionInfo(c.Ci)

	// marshal request
	subSpan := telemetry.StartSpan(&c.Ctx, "i2b2client", "xmlRequest:Marshall")
	marshaledRequest, err := xml.MarshalIndent(xmlRequest, "  ", "    ")
	subSpan.End()
	if err != nil {
		return fmt.Errorf("marshalling i2b2 request marshalling: %v", err)
	}
	marshaledRequest = append([]byte(xml.Header), marshaledRequest...)
	c.Logger.Debugf("i2b2 request:\n%v", string(marshaledRequest))

	// execute HTTP request
	subSpan = telemetry.StartSpan(&c.Ctx, "i2b2client", "xmlRequest:Post")
	httpResponse, err := otelhttp.Post(c.Ctx, reqURL, "text/xml", bytes.NewReader(marshaledRequest))
	subSpan.End()
	if err != nil {
		return fmt.Errorf("making HTTP POST of XML request: %v", err)
	}
	defer httpResponse.Body.Close()

	// unmarshal response
	subSpan = telemetry.StartSpan(&c.Ctx, "i2b2client", "xmlRequest:Response:ReadAll")
	httpBody, err := io.ReadAll(httpResponse.Body)
	subSpan.SetAttributes(attribute.Key("httpBodySize").Int(len(httpBody)))
	subSpan.End()
	if err != nil {
		return fmt.Errorf("reading XML response: %v", err)
	}
	// c.Logger.Debugf("i2b2 response:\n%v", string(httpBody))

	subSpan = telemetry.StartSpan(&c.Ctx, "i2b2client", "xmlRequest:Response:UnMarshall")
	err = xml.Unmarshal(httpBody, xmlResponse)
	subSpan.End()
	if err != nil {
		return fmt.Errorf("unmarshalling XML response: %v", err)
	}

	// check i2b2 request status
	if err := xmlResponse.CheckStatus(); err != nil {
		return fmt.Errorf("found error in i2b2 response: %v", err)
	}
	return nil
}
