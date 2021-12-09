package models

import "fmt"

type parseError error

func recoverParseError(retErr *error) {
	if r := recover(); r != nil {
		if parseErr, ok := r.(parseError); !ok {
			panic(r) // panic was not caused by a parse error
		} else {
			*retErr = fmt.Errorf("parsing value: %v", parseErr)
		}
	}
}

func getString(params map[string]interface{}, key string) string {
	if stringVal, ok := params[key]; !ok {
		panic(parseError(fmt.Errorf("key \"%v\" not found in params", key)))
	} else if stringCast, ok := stringVal.(string); !ok {
		panic(parseError(fmt.Errorf("key \"%v\" is not a string (%T)", key, stringVal)))
	} else {
		return stringCast
	}
}
