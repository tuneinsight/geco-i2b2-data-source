package models

import i2b2clientmodels "github.com/ldsec/geco-i2b2-data-source/pkg/i2b2client/models"

// --- parameters

// SearchConceptParameters is the parameter for the SearchConcept operation.
type SearchConceptParameters struct {
	Path      string
	Operation string // children | info
}

// SearchModifierParameters is the parameter for the SearchModifier operation.
type SearchModifierParameters struct {
	SearchConceptParameters // Operation: children | info | concept
	AppliedPath             string
	AppliedConcept          string
}

// --- results

// SearchResults is the result of the Search operations.
type SearchResults struct {
	SearchResults []SearchResult
}

// NewSearchResultFromI2b2Concept creates a new SearchResult from an i2b2 concept.
func NewSearchResultFromI2b2Concept(concept i2b2clientmodels.Concept) SearchResult {
	parsed := SearchResult{
		Name:        concept.Name,
		DisplayName: concept.Name,
		Code:        concept.Basecode,
		Path:        i2b2clientmodels.ConvertPathFromI2b2Format(concept.Key),
		AppliedPath: "@",
		Comment:     concept.Comment,
	}

	// parse i2b2 visual attributes
	switch concept.Visualattributes[0] {
	// i2b2 leaf
	case 'L':
		parsed.Type = "concept"
		parsed.Leaf = true
	case 'R':
		parsed.Type = "modifier"
		parsed.Leaf = true

	// i2b2 container
	case 'C':
		parsed.Type = "concept_container"
		parsed.Leaf = false
	case 'O':
		parsed.Type = "modifier_container"
		parsed.Leaf = false

	// i2b2 folder (& default)
	default:
		fallthrough
	case 'F':
		parsed.Type = "concept_folder"
		parsed.Leaf = false
	case 'D':
		parsed.Type = "modifier_folder"
		parsed.Leaf = false
	}

	if concept.Metadataxml != nil {
		parsed.Metadata = SearchResultMetadata{
			DataType:      concept.Metadataxml.DataType,
			OkToUseValues: concept.Metadataxml.Oktousevalues,
			UnitValues:    MetadataUnitValues{NormalUnits: concept.Metadataxml.UnitValues.NormalUnits},
		}
	}

	return parsed
}

// NewSearchResultFromI2b2Modifier creates a new SearchResult from an i2b2 modifier.
func NewSearchResultFromI2b2Modifier(modifier i2b2clientmodels.Modifier) SearchResult {
	res := NewSearchResultFromI2b2Concept(modifier.Concept)
	res.AppliedPath = i2b2clientmodels.ConvertPathFromI2b2Format(modifier.AppliedPath)
	return res
}

// SearchResult is a result part of SearchResults.
type SearchResult struct {
	Path        string
	AppliedPath string
	Name        string
	DisplayName string
	Code        string
	Comment     string
	Type        string // concept | concept_container | concept_folder | modifier | modifier_container | modifier_folder | genomic_annotation
	Leaf        bool
	Metadata    SearchResultMetadata
}

// SearchResultMetadata is part of SearchResult.
type SearchResultMetadata struct {
	DataType      string // PosInteger | Integer | Float | PosFloat | Enum | String
	OkToUseValues string // Y
	UnitValues    MetadataUnitValues
}

// MetadataUnitValues is part of SearchResultMetadata.
type MetadataUnitValues struct {
	NormalUnits string
}
