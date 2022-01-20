package models

import (
	"encoding/xml"
)

// --- request

// NewOntReqGetTermInfoMessageBody returns a new message body for a request object for concept info.
func NewOntReqGetTermInfoMessageBody(ontMaxElements, path string) OntReqGetTermInfoMessageBody {
	body := OntReqGetTermInfoMessageBody{}

	body.GetTermInfo.Hiddens = "false"
	body.GetTermInfo.Blob = "true"
	body.GetTermInfo.Synonyms = "false"
	body.GetTermInfo.Max = ontMaxElements
	body.GetTermInfo.Type = "core"
	body.GetTermInfo.Self = path

	return body
}

// NewOntReqGetCategoriesMessageBody returns a new message body for a request object for i2b2 categories (ontology root nodes).
func NewOntReqGetCategoriesMessageBody() OntReqGetCategoriesMessageBody {
	body := OntReqGetCategoriesMessageBody{}

	body.GetCategories.Hiddens = "false"
	body.GetCategories.Blob = "true"
	body.GetCategories.Synonyms = "false"
	body.GetCategories.Type = "core"

	return body
}

// NewOntReqGetChildrenMessageBody returns a new message body for a request object for i2b2 children of a node.
func NewOntReqGetChildrenMessageBody(ontMaxElements, parent string) OntReqGetChildrenMessageBody {
	body := OntReqGetChildrenMessageBody{}

	body.GetChildren.Hiddens = "false"
	body.GetChildren.Blob = "true"
	body.GetChildren.Synonyms = "false"
	body.GetChildren.Max = ontMaxElements
	body.GetChildren.Type = "core"

	body.GetChildren.Parent = parent

	return body
}

// NewOntReqGetModifierInfoMessageBody returns a new message body for a request object for modifier info.
func NewOntReqGetModifierInfoMessageBody(path string, appliedPath string) OntReqGetModifierInfoMessageBody {
	body := OntReqGetModifierInfoMessageBody{}

	body.GetModifierInfo.Hiddens = "false"
	body.GetModifierInfo.Blob = "true"
	body.GetModifierInfo.Synonyms = "false"
	body.GetModifierInfo.Type = "core"
	body.GetModifierInfo.Self = path
	body.GetModifierInfo.AppliedPath = appliedPath

	return body
}

// NewOntReqGetModifiersMessageBody returns a new request object to get the i2b2 modifiers that apply to the concept path.
func NewOntReqGetModifiersMessageBody(self string) OntReqGetModifiersMessageBody {
	body := OntReqGetModifiersMessageBody{}

	body.GetModifiers.Blob = "true"
	body.GetModifiers.Hiddens = "false"
	body.GetModifiers.Synonyms = "false"

	body.GetModifiers.Self = self

	return body
}

// NewOntReqGetModifierChildrenMessageBody returns a new message body for a request object to get the children of a modifier.
func NewOntReqGetModifierChildrenMessageBody(ontMaxElements, parent, appliedPath, appliedConcept string) OntReqGetModifierChildrenMessageBody {
	body := OntReqGetModifierChildrenMessageBody{}

	body.GetModifierChildren.Blob = "true"
	body.GetModifierChildren.Type = "limited"
	body.GetModifierChildren.Max = ontMaxElements
	body.GetModifierChildren.Synonyms = "false"
	body.GetModifierChildren.Hiddens = "false"

	body.GetModifierChildren.Parent = parent
	body.GetModifierChildren.AppliedPath = appliedPath
	body.GetModifierChildren.AppliedConcept = appliedConcept

	return body
}

type baseMessageBody struct {
	Hiddens  string `xml:"hiddens,attr,omitempty"`
	Synonyms string `xml:"synonyms,attr,omitempty"`
	Type     string `xml:"type,attr,omitempty"`
	Blob     string `xml:"blob,attr,omitempty"`
	Max      string `xml:"max,attr,omitempty"`
}

// OntReqGetTermInfoMessageBody is an i2b2 XML message for ontology concept info request.
type OntReqGetTermInfoMessageBody struct {
	XMLName     xml.Name `xml:"message_body"`
	GetTermInfo struct {
		baseMessageBody
		Self string `xml:"self"`
	} `xml:"ontns:get_term_info"`
}

// OntReqGetCategoriesMessageBody is an i2b2 XML message body for ontology categories request.
type OntReqGetCategoriesMessageBody struct {
	XMLName       xml.Name `xml:"message_body"`
	GetCategories struct {
		baseMessageBody
	} `xml:"ontns:get_categories"`
}

// OntReqGetChildrenMessageBody is an i2b2 XML message for ontology children request.
type OntReqGetChildrenMessageBody struct {
	XMLName     xml.Name `xml:"message_body"`
	GetChildren struct {
		baseMessageBody
		Parent string `xml:"parent"`
	} `xml:"ontns:get_children"`
}

// OntReqGetModifierInfoMessageBody is an i2b2 XML message for ontology modifier info request.
type OntReqGetModifierInfoMessageBody struct {
	XMLName         xml.Name `xml:"message_body"`
	GetModifierInfo struct {
		baseMessageBody
		Self        string `xml:"self"`
		AppliedPath string `xml:"applied_path"`
	} `xml:"ontns:get_modifier_info"`
}

// OntReqGetModifiersMessageBody is an i2b2 XML message for ontology modifiers request.
type OntReqGetModifiersMessageBody struct {
	XMLName      xml.Name `xml:"message_body"`
	GetModifiers struct {
		baseMessageBody
		Self string `xml:"self"`
	} `xml:"ontns:get_modifiers"`
}

// OntReqGetModifierChildrenMessageBody is an i2b2 XML message for ontology modifier children request.
type OntReqGetModifierChildrenMessageBody struct {
	XMLName             xml.Name `xml:"message_body"`
	GetModifierChildren struct {
		baseMessageBody
		Parent         string `xml:"parent"`
		AppliedPath    string `xml:"applied_path"`
		AppliedConcept string `xml:"applied_concept"`
	} `xml:"ontns:get_modifier_children"`
}

// --- response

// OntRespConceptsMessageBody is the message_body of the i2b2 get_children response message
type OntRespConceptsMessageBody struct {
	XMLName  xml.Name  `xml:"message_body"`
	Concepts []Concept `xml:"concepts>concept"`
}

// OntRespModifiersMessageBody is the message_body of the i2b2 get_modifiers response message.
type OntRespModifiersMessageBody struct {
	XMLName   xml.Name   `xml:"message_body"`
	Modifiers []Modifier `xml:"modifiers>modifier"`
}

// Concept is an i2b2 XML concept
type Concept struct {
	Level            string       `xml:"level"`
	Key              string       `xml:"key"`
	Name             string       `xml:"name"`
	SynonymCd        string       `xml:"synonym_cd"`
	Visualattributes string       `xml:"visualattributes"`
	Totalnum         string       `xml:"totalnum"`
	Basecode         string       `xml:"basecode"`
	Metadataxml      *MetadataXML `xml:"metadataxml"`
	Facttablecolumn  string       `xml:"facttablecolumn"`
	Tablename        string       `xml:"tablename"`
	Columnname       string       `xml:"columnname"`
	Columndatatype   string       `xml:"columndatatype"`
	Operator         string       `xml:"operator"`
	Dimcode          string       `xml:"dimcode"`
	Comment          string       `xml:"comment"`
	Tooltip          string       `xml:"tooltip"`
	UpdateDate       string       `xml:"update_date"`
	DownloadDate     string       `xml:"download_date"`
	ImportDate       string       `xml:"import_date"`
	SourcesystemCd   string       `xml:"sourcesystem_cd"`
	ValuetypeCd      string       `xml:"valuetype_cd"`
}

// Modifier is an i2b2 XML modifier.
type Modifier struct {
	Concept
	AppliedPath string `xml:"applied_path"`
}

// MetadataXML is the metadata of a Concept.
type MetadataXML struct {
	CreationDateTime string                  `xml:"ValueMetadata>CreationDateTime"`
	DataType         string                  `xml:"ValueMetadata>DataType"`
	EnumValues       string                  `xml:"ValueMetadata>EnumValues"`
	Flagstouse       string                  `xml:"ValueMetadata>Flagstouse"`
	Oktousevalues    string                  `xml:"ValueMetadata>Oktousevalues"`
	TestID           string                  `xml:"ValueMetadata>TestID"`
	TestName         string                  `xml:"ValueMetadata>TestName"`
	UnitValues       ValueMetadataUnitValues `xml:"ValueMetadata>UnitValues"`
	Version          string                  `xml:"ValueMetadata>Version"`
}

// ValueMetadataUnitValues is part of MetadataXML.
type ValueMetadataUnitValues struct {
	ConvertingUnits []UnitValuesConvertingUnits `xml:"ConvertingUnits"`
	EqualUnits      []string                    `xml:"EqualUnits"`
	ExcludingUnits  []string                    `xml:"ExcludingUnits"`
	NormalUnits     string                      `xml:"NormalUnits"`
}

// UnitValuesConvertingUnits is part of ValueMetadataUnitValues.
type UnitValuesConvertingUnits struct {
	MultiplyingFactor string `xml:"MultiplyingFactor"`
	Units             string `xml:"Units"`
}
