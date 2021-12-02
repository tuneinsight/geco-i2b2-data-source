#!/usr/bin/env bash
set -Eeuo pipefail

function postXmlI2b2 {
  I2B2_ENDPOINT="$1"
  REQ_XML="$2"
  RESP_XML="$3"

  echo "HTTP POST $I2B2_ENDPOINT of $REQ_XML..."
  curl -v --header "Content-Type:application/xml" -d "@$REQ_XML" -o "$RESP_XML" "http://localhost:8080/i2b2/services/$I2B2_ENDPOINT" > "$RESP_XML.log" 2>&1

  echo "Checking HTTP code..."
  grep "HTTP/1.1 200 OK" "$RESP_XML.log"
}

MSG=pm_get_user_configuration
postXmlI2b2 PMService/getServices "${MSG}_req.xml" "${MSG}_resp.xml"
xmllint --xpath "string(//status)" "${MSG}_resp.xml" | grep "PM processing completed"
xmllint --xpath "string(//password)" "${MSG}_resp.xml" | grep "SessionKey"

# todo: with test data, fails with empty DB
#MSG=ont_get_categories
#postXmlI2b2 TBD "${MSG}_req.xml" "${MSG}_resp.xml"
#xmllint --xpath "string(//TBD)" "${MSG}_resp.xml" | grep "TBD"
