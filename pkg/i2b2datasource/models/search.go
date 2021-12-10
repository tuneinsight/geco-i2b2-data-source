package models

// --- parameters

// func NewSearchConceptParameters(params map[string]interface{}) (model SearchConceptParameters, retErr error) {
// 	defer recoverParseError(&retErr)
//
// 	return SearchConceptParameters{
// 		Path:      getString(params, "path"),
// 		Operation: getString(params, "operation"),
// 	}, nil
// }

type SearchConceptParameters struct {
	Path      string
	Operation string // children | info | concept
}

// func NewSearchModifierParameters(params map[string]interface{}) (model SearchModifierParameters, retErr error) {
// 	defer recoverParseError(&retErr)
//
// 	return SearchModifierParameters{
// 		SearchConceptParameters: SearchConceptParameters{
// 			Path: getString(params, "path"),
// 			Operation: getString(params, "operation"),
// 		},
// 		AppliedPath:             getString(params, "appliedPath"),
// 		AppliedConcept:          getString(params, "appliedConcept"),
// 	}, nil
// }

// todo: maybe squash model together if OK with serializing etc.

type SearchModifierParameters struct {
	SearchConceptParameters
	AppliedPath    string
	AppliedConcept string
}

// --- results

type SearchResults struct {
	SearchResults []SearchResult
}

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

type SearchResultMetadata struct {
	DataType      string // PosInteger | Integer | Float | PosFloat | Enum | String
	OkToUseValues string // Y
	UnitValues    MetadataUnitValues
}

type MetadataUnitValues struct {
	NormalUnits string
}
