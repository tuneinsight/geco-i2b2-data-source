package models

import "strings"

func ConvertPathToI2b2Format(path string) string {
	return `\` + strings.Replace(path, "/", `\`, -1)
}

func ConvertPathFromI2b2Format(path string) string {
	return strings.Replace(strings.Replace(path, `\`, "/", -1), "//", "/", 1)
}
