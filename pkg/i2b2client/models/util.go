package models

import (
	"strings"
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

// ConvertAppliedPathToI2b2Format converts a GeCo applied path to an i2b2 applied path format
func ConvertAppliedPathToI2b2Format(path string) string {
	return strings.Replace(path, "/", `\`, -1)
}

// ConvertPathToI2b2Format converts a GeCo ontology path to an i2b2 path format
func ConvertPathToI2b2Format(path string) string {
	return `\` + strings.Replace(path, "/", `\`, -1)
}

// ConvertPathFromI2b2Format converts an i2b2 ontology path to a GeCo path format
func ConvertPathFromI2b2Format(path string) string {
	return strings.Replace(strings.Replace(path, `\`, "/", -1), "//", "/", 1)
}
