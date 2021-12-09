package i2b2datasource

import (
	"fmt"
	"strings"

	i2b2apimodels "github.com/ldsec/geco-i2b2-data-source/pkg/i2b2api/models"
	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2datasource/models"
)

// SearchConcept retrieves the info about or the children of the concept identified by path.
func (ds I2b2DataSource) SearchConcept(params *models.SearchConceptParameters) (*models.SearchResults, error) {

	// make the appropriate request to i2b2
	path := strings.TrimSpace(params.Path)
	i2b2FormatPath := i2b2apimodels.ConvertPathToI2b2Format(path)
	var resp *i2b2apimodels.OntRespConceptsMessageBody
	var err error

	if len(path) == 0 {
		return nil, fmt.Errorf("empty path")
	}

	switch params.Operation {
	case "info":
		if path == "/" {
			return &models.SearchResults{SearchResults: make([]models.SearchResult, 0)}, nil
		} else {
			req := i2b2apimodels.NewOntReqGetTermInfoMessageBody(ds.i2b2OntMaxElements, i2b2FormatPath)
			if resp, err = ds.i2b2Client.OntGetTermInfo(&req); err != nil {
				return nil, fmt.Errorf("requesting term info: %v", err)
			}
		}

	case "children":
		if path == "/" {
			req := i2b2apimodels.NewOntReqGetCategoriesMessageBody()
			if resp, err = ds.i2b2Client.OntGetCategories(&req); err != nil {
				return nil, fmt.Errorf("requesting categories: %v", err)
			}

		} else {
			req := i2b2apimodels.NewOntReqGetChildrenMessageBody(ds.i2b2OntMaxElements, i2b2FormatPath)
			if resp, err = ds.i2b2Client.OntGetChildren(&req); err != nil {
				return nil, fmt.Errorf("requesting children: %v", err)
			}
		}

	default:
		return nil, fmt.Errorf("invalid search operation: %v", params.Operation)
	}

	// generate result from response
	searchResults := make([]models.SearchResult, 0, len(resp.Concepts))
	for _, concept := range resp.Concepts {
		searchResults = append(searchResults, parseI2b2Concept(concept))
	}
	return &models.SearchResults{SearchResults: searchResults}, nil
}

func parseI2b2Concept(concept i2b2apimodels.Concept) models.SearchResult {

	parsed := models.SearchResult{
		Name:        concept.Name,
		DisplayName: concept.Name,
		Code:        concept.Basecode,
		Path:        i2b2apimodels.ConvertPathFromI2b2Format(concept.Key),
		AppliedPath: "@",
		Comment:     concept.Comment,
	}

	parsed.Type, parsed.Leaf = parseI2b2VisualAttributes(concept.Visualattributes)

	if concept.Metadataxml != nil {
		parsed.Metadata = models.SearchResultMetadata{
			DataType:      concept.Metadataxml.DataType,
			Oktousevalues: concept.Metadataxml.Oktousevalues,
			UnitValues: struct {
				NormalUnits string
			}{
				NormalUnits: concept.Metadataxml.UnitValues.NormalUnits,
			},
		}
	}

	return parsed
}

func parseI2b2VisualAttributes(visualAttributes string) (kind string, leaf bool) {
	switch visualAttributes[0] {
	// i2b2 leaf
	case 'L':
		return "concept", true
	case 'R':
		return "modifier", true

	// i2b2 container
	case 'C':
		return "concept_container", false
	case 'O':
		return "modifier_container", false

	// i2b2 folder (& default)
	default:
		fallthrough
	case 'F':
		return "concept_folder", false
	case 'D':
		return "modifier_folder", false
	}
}

// SearchModifier retrieves the info about or the children of the modifier identified by path.
func (ds I2b2DataSource) SearchModifier(params *models.SearchModifierParameters) (*models.SearchResults, error) {

	// make the appropriate request to i2b2
	path := strings.TrimSpace(params.Path)
	i2b2FormatPath := i2b2apimodels.ConvertPathToI2b2Format(path)
	var resp *i2b2apimodels.OntRespModifiersMessageBody
	var err error

	if len(path) == 0 {
		return nil, fmt.Errorf("empty path")
	}

	switch params.Operation {
	case "concept":
		if path == "/" {
			return &models.SearchResults{SearchResults: make([]models.SearchResult, 0)}, nil

		} else {
			req := i2b2apimodels.NewOntReqGetModifiersMessageBody(i2b2FormatPath)
			if resp, err = ds.i2b2Client.OntGetModifiers(&req); err != nil {
				return nil, fmt.Errorf("requesting modifiers of concept: %v", err)
			}
		}

	case "info":
		if path == "/" {
			return &models.SearchResults{SearchResults: make([]models.SearchResult, 0)}, nil

		} else {
			i2b2FormatAppliedPath := i2b2apimodels.ConvertAppliedPathToI2b2Format(strings.TrimSpace(params.AppliedPath))
			req := i2b2apimodels.NewOntReqGetModifierInfoMessageBody(i2b2FormatPath, i2b2FormatAppliedPath)
			if resp, err = ds.i2b2Client.OntGetModifierInfo(&req); err != nil {
				return nil, fmt.Errorf("requesting info of modifier: %v", err)
			}
		}

	case "children":
		if path == "/" {
			return &models.SearchResults{SearchResults: make([]models.SearchResult, 0)}, nil

		} else {
			i2b2FormatAppliedPath := i2b2apimodels.ConvertAppliedPathToI2b2Format(strings.TrimSpace(params.AppliedPath))
			i2b2FormatAppliedConcept := i2b2apimodels.ConvertPathToI2b2Format(strings.TrimSpace(params.AppliedConcept))
			req := i2b2apimodels.NewOntReqGetModifierChildrenMessageBody(ds.i2b2OntMaxElements, i2b2FormatPath, i2b2FormatAppliedPath, i2b2FormatAppliedConcept)
			if resp, err = ds.i2b2Client.OntGetModifierChildren(&req); err != nil {
				return nil, fmt.Errorf("requesting children of modifier: %v", err)
			}
		}

	default:
		return nil, fmt.Errorf("invalid search operation: %v", params.Operation)
	}

	// generate result from response
	searchResults := make([]models.SearchResult, 0, len(resp.Modifiers))
	for _, modifier := range resp.Modifiers {
		searchResults = append(searchResults, parseI2b2Modifier(modifier))
	}
	return &models.SearchResults{SearchResults: searchResults}, nil
}

func parseI2b2Modifier(modifier i2b2apimodels.Modifier) models.SearchResult {
	res := parseI2b2Concept(modifier.Concept)
	res.AppliedPath = i2b2apimodels.ConvertPathFromI2b2Format(modifier.AppliedPath)
	return res
}
