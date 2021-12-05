package models

// todo: those are c/c from swagger-generated medco models, they should be updated according to the definition of the API exposed through geco

// APIPanel todo: should be changed according to the API exposed
type APIPanel struct {

	// items containing cohort names
	CohortItems []string `json:"cohortItems"`

	// items containing i2b2 concepts (and optionally modifiers)
	ConceptItems []*APIPanelConceptItemsItems0 `json:"conceptItems"`

	// exclude the i2b2 panel
	// Required: true
	Not *bool `json:"not"`

	// panel timing
	PanelTiming APITiming `json:"panelTiming,omitempty"`
}

// APIPanelConceptItemsItems0 todo: should be changed according to the API exposed
type APIPanelConceptItemsItems0 struct {

	// encrypted
	// Required: true
	Encrypted *bool `json:"encrypted"`

	// modifier
	Modifier *APIPanelConceptItemsItems0Modifier `json:"modifier,omitempty"`

	// # NUMBER operators EQ: equal NE: not equal GT: greater than GE: greater than or equal LT: less than LE: less than or equal BETWEEN: between (value syntax: "x and y") # TEXT operators IN: in (value syntax: "'x','y','z'") LIKE[exact]: equal LIKE[begin]: begins with LIKE[end]: ends with LIKE[contains]: contains
	//
	// Enum: [EQ NE GT GE LT LE BETWEEN IN LIKE[exact] LIKE[begin] LIKE[end] LIKE[contains]]
	Operator string `json:"operator,omitempty"`

	// query term
	// Required: true
	// Pattern: ^([\w=-]+)$|^((\/[^\/]+)+\/)$
	QueryTerm *string `json:"queryTerm"`

	// type
	// Enum: [NUMBER TEXT]
	Type string `json:"type,omitempty"`

	// value
	Value string `json:"value,omitempty"`
}

// APIPanelConceptItemsItems0Modifier todo: should be changed according to the API exposed
type APIPanelConceptItemsItems0Modifier struct {

	// applied path
	// Required: true
	// Pattern: ^((\/[^\/]+)+\/%?)$
	AppliedPath *string `json:"appliedPath"`

	// modifier key
	// Required: true
	// Pattern: ^((\/[^\/]+)+\/)$
	ModifierKey *string `json:"modifierKey"`
}

// APITiming todo: should be changed according to the API exposed
type APITiming string
const (
	// APITimingAny captures enum value "any"
	APITimingAny APITiming = "any"

	// APITimingSamevisit captures enum value "samevisit"
	APITimingSamevisit APITiming = "samevisit"

	// APITimingSameinstancenum captures enum value "sameinstancenum"
	APITimingSameinstancenum APITiming = "sameinstancenum"
)

// Metadataxml todo: should be changed according to the API exposed
type Metadataxml struct {

	// value metadata
	ValueMetadata *MetadataxmlValueMetadata `json:"ValueMetadata,omitempty"`
}


// MetadataxmlValueMetadata todo: should be changed according to the API exposed
type MetadataxmlValueMetadata struct {

	// children encrypt i ds
	ChildrenEncryptIDs string `json:"ChildrenEncryptIDs,omitempty"`

	// creation date time
	CreationDateTime string `json:"CreationDateTime,omitempty"`

	// data type
	DataType string `json:"DataType,omitempty"`

	// encrypted type
	EncryptedType string `json:"EncryptedType,omitempty"`

	// enum values
	EnumValues string `json:"EnumValues,omitempty"`

	// flagstouse
	Flagstouse string `json:"Flagstouse,omitempty"`

	// node encrypt ID
	NodeEncryptID string `json:"NodeEncryptID,omitempty"`

	// oktousevalues
	Oktousevalues string `json:"Oktousevalues,omitempty"`

	// test ID
	TestID string `json:"TestID,omitempty"`

	// test name
	TestName string `json:"TestName,omitempty"`

	// unit values
	UnitValues *UnitValues `json:"UnitValues,omitempty"`

	// version
	Version string `json:"Version,omitempty"`
}

// UnitValues todo: should be changed according to the API exposed
type UnitValues struct {

	// converting units
	ConvertingUnits []*UnitValuesConvertingUnitsItems0 `json:"ConvertingUnits"`

	// equal units
	EqualUnits []string `json:"EqualUnits"`

	// excluding units
	ExcludingUnits []string `json:"ExcludingUnits"`

	// normal units
	NormalUnits string `json:"NormalUnits,omitempty"`
}

// UnitValuesConvertingUnitsItems0 todo: should be changed according to the API exposed
type UnitValuesConvertingUnitsItems0 struct {

	// multiplying factor
	MultiplyingFactor string `json:"MultiplyingFactor,omitempty"`

	// units
	Units string `json:"Units,omitempty"`
}
