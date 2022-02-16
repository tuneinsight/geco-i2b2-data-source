package models

import (
	i2b2clientmodels "github.com/tuneinsight/geco-i2b2-data-source/pkg/i2b2client/models"
)

// --- parameters

// SearchConceptParameters are the parameters for the searchConcept Operation.
type SearchConceptParameters struct {
	Path      string `json:"path"`
	Operation string `json:"operation"` // children | info
}

// SearchModifierParameters are the parameters for the searchModifier Operation.
type SearchModifierParameters struct {
	SearchConceptParameters        // Operation: children | info | concept
	AppliedPath             string `json:"appliedPath"`
	AppliedConcept          string `json:"appliedConcept"`
}

// SearchOntologyParameters are the parameter for the searchOntology Operation.
type SearchOntologyParameters struct {
	// Maximum number of returned ontology elements (default 10).
	Limit string `json:"limit,omitempty"`
	// String to search for in concepts and modifiers paths.
	SearchString *string `json:"searchString"`
}

// --- results

// SearchResult is the result of the Search operations.
type SearchResult struct {
	SearchResultElements []*SearchResultElement `json:"searchResult"`
}

// SearchResultElement is an element (concept of modifier) of SearchResult.
type SearchResultElement struct {
	Path        string               `json:"path"`
	AppliedPath string               `json:"appliedPath"`
	Name        string               `json:"name"`
	DisplayName string               `json:"displayName"`
	Code        string               `json:"code"`
	Comment     string               `json:"comment,omitempty"`
	Type        string               `json:"type,omitempty"` // concept | concept_container | concept_folder | modifier | modifier_container | modifier_folder | genomic_annotation
	Leaf        bool                 `json:"leaf"`
	Metadata    *MetadataJSON        `json:"metadata,omitempty"`
	Parent      *SearchResultElement `json:"parent,omitempty"`
}

// MetadataJSON is the JSON representation of the XML metadata of an i2b2 ontology element.
type MetadataJSON struct {
	CreationDateTime string           `json:"creationDateTime,omitempty"`
	DataType         string           `json:"dataType,omitempty"` // PosInteger | Integer | Float | PosFloat | Enum | String
	EnumValues       string           `json:"enumValues,omitempty"`
	FlagsToUse       string           `json:"flagsToUse,omitempty"`
	OkToUseValues    string           `json:"okToUseValues,omitempty"` // Y
	TestID           string           `json:"testID,omitempty"`
	TestName         string           `json:"testName,omitempty"`
	UnitValues       []*UnitValueJSON `json:"unitValues,omitempty"`
	Version          string           `json:"version,omitempty"`
}

// UnitValueJSON is a unit value of a MetadataJSON.
type UnitValueJSON struct {
	ConvertingUnits []*ConvertingUnitJSON `json:"convertingUnits"`
	EqualUnits      []string              `json:"equalUnits"`
	ExcludingUnits  []string              `json:"excludingUnits"`
	NormalUnits     string                `json:"normalUnits,omitempty"`
}

// ConvertingUnitJSON is a converting unit of a UnitValueJSON.
type ConvertingUnitJSON struct {
	MultiplyingFactor string `json:"multiplyingFactor,omitempty"`
	Units             string `json:"units,omitempty"`
}

// NewSearchResultFromI2b2Concept creates a new SearchResultElement from an i2b2 concept.
func NewSearchResultFromI2b2Concept(concept i2b2clientmodels.Concept) *SearchResultElement {
	return NewSearchResultFromI2b2OntologyElement(i2b2clientmodels.OntologyElement(concept))
}

// NewSearchResultFromI2b2Modifier creates a new SearchResultElement from an i2b2 modifier.
func NewSearchResultFromI2b2Modifier(modifier i2b2clientmodels.Modifier) *SearchResultElement {
	return NewSearchResultFromI2b2OntologyElement(i2b2clientmodels.OntologyElement(modifier))
}

// NewSearchResultFromI2b2OntologyElement creates a new SearchResultElement from an i2b2 ontology element (concept or modifier).
func NewSearchResultFromI2b2OntologyElement(ontologyElement i2b2clientmodels.OntologyElement) *SearchResultElement {

	searchResultElement := &SearchResultElement{
		Name:        ontologyElement.Name,
		DisplayName: ontologyElement.Name,
		Code:        ontologyElement.Basecode,
		Path:        i2b2clientmodels.ConvertPathFromI2b2Format(ontologyElement.Key),
		AppliedPath: ontologyElement.AppliedPath,
		Comment:     ontologyElement.Comment,
	}

	if ontologyElement.AppliedPath != "@" {
		searchResultElement.AppliedPath = i2b2clientmodels.ConvertPathFromI2b2Format(ontologyElement.AppliedPath)
	}

	// parse i2b2 visual attributes
	switch ontologyElement.Visualattributes[0] {
	// i2b2 leaf
	case 'L':
		searchResultElement.Type = "concept"
		searchResultElement.Leaf = true
	case 'R':
		searchResultElement.Type = "modifier"
		searchResultElement.Leaf = true

	// i2b2 container
	case 'C':
		searchResultElement.Type = "concept_container"
		searchResultElement.Leaf = false
	case 'O':
		searchResultElement.Type = "modifier_container"
		searchResultElement.Leaf = false

	// i2b2 folder (& default)
	default:
		fallthrough
	case 'F':
		searchResultElement.Type = "concept_folder"
		searchResultElement.Leaf = false
	case 'D':
		searchResultElement.Type = "modifier_folder"
		searchResultElement.Leaf = false
	}

	// parse the metadata
	if ontologyElement.Metadataxml != nil {
		var unitValues []*UnitValueJSON
		for _, unitValue := range ontologyElement.Metadataxml.UnitValues {

			var convertingUnits []*ConvertingUnitJSON
			for _, convertingUnit := range unitValue.ConvertingUnits {
				convertingUnits = append(convertingUnits, &ConvertingUnitJSON{
					MultiplyingFactor: convertingUnit.MultiplyingFactor,
					Units:             convertingUnit.Units,
				})
			}

			unitValues = append(unitValues, &UnitValueJSON{
				ConvertingUnits: convertingUnits,
				EqualUnits:      unitValue.EqualUnits,
				ExcludingUnits:  unitValue.ExcludingUnits,
				NormalUnits:     unitValue.NormalUnits,
			})
		}

		searchResultElement.Metadata = &MetadataJSON{
			CreationDateTime: ontologyElement.Metadataxml.CreationDateTime,
			DataType:         ontologyElement.Metadataxml.DataType,
			EnumValues:       ontologyElement.Metadataxml.EnumValues,
			FlagsToUse:       ontologyElement.Metadataxml.Flagstouse,
			OkToUseValues:    ontologyElement.Metadataxml.Oktousevalues,
			TestID:           ontologyElement.Metadataxml.TestID,
			TestName:         ontologyElement.Metadataxml.TestName,
			UnitValues:       unitValues,
			Version:          ontologyElement.Metadataxml.Version,
		}
	}

	return searchResultElement
}
