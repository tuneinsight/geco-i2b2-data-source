package datasource

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/ldsec/geco-i2b2-data-source/pkg/datasource/models"
	i2b2clientmodels "github.com/ldsec/geco-i2b2-data-source/pkg/i2b2client/models"
	gecomodels "github.com/ldsec/geco/pkg/models"
	gecosdk "github.com/ldsec/geco/pkg/sdk"
)

// SearchConceptHandler is the OperationHandler for the searchConcept Operation.
func (ds I2b2DataSource) SearchConceptHandler(_ string, jsonParameters []byte, _ map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID) (jsonResults []byte, _ []gecosdk.DataObject, err error) {
	decodedParams := &models.SearchConceptParameters{}
	if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("decoding parameters: %v", err)
	} else if searchResults, err := ds.SearchConcept(decodedParams); err != nil {
		return nil, nil, fmt.Errorf("executing query: %v", err)
	} else if jsonResults, err = json.Marshal(searchResults); err != nil {
		return nil, nil, fmt.Errorf("encoding results: %v", err)
	}
	return
}

// SearchConcept retrieves the info about or the children of the concept identified by path.
func (ds I2b2DataSource) SearchConcept(params *models.SearchConceptParameters) (*models.SearchResults, error) {

	// make the appropriate request to i2b2
	path := strings.TrimSpace(params.Path)
	i2b2FormatPath := i2b2clientmodels.ConvertPathToI2b2Format(path)
	var resp *i2b2clientmodels.OntRespConceptsMessageBody
	var err error

	if len(path) == 0 {
		return nil, fmt.Errorf("empty path")
	}

	switch params.Operation {
	case "info":
		if path == "/" {
			return &models.SearchResults{SearchResults: make([]models.SearchResult, 0)}, nil
		}

		req := i2b2clientmodels.NewOntReqGetTermInfoMessageBody(ds.i2b2OntMaxElements, i2b2FormatPath)
		if resp, err = ds.i2b2Client.OntGetTermInfo(&req); err != nil {
			return nil, fmt.Errorf("requesting term info: %v", err)
		}

	case "children":
		if path == "/" {
			req := i2b2clientmodels.NewOntReqGetCategoriesMessageBody()
			if resp, err = ds.i2b2Client.OntGetCategories(&req); err != nil {
				return nil, fmt.Errorf("requesting categories: %v", err)
			}
			break
		}

		req := i2b2clientmodels.NewOntReqGetChildrenMessageBody(ds.i2b2OntMaxElements, i2b2FormatPath)
		if resp, err = ds.i2b2Client.OntGetChildren(&req); err != nil {
			return nil, fmt.Errorf("requesting children: %v", err)
		}

	default:
		return nil, fmt.Errorf("invalid search operation: %v", params.Operation)
	}

	// generate result from response
	searchResults := make([]models.SearchResult, 0, len(resp.Concepts))
	for _, concept := range resp.Concepts {
		searchResults = append(searchResults, models.NewSearchResultFromI2b2Concept(concept))
	}
	return &models.SearchResults{SearchResults: searchResults}, nil
}

// SearchModifierHandler is the OperationHandler for the searchModifier Operation.
func (ds I2b2DataSource) SearchModifierHandler(_ string, jsonParameters []byte, _ map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID) (jsonResults []byte, _ []gecosdk.DataObject, err error) {
	decodedParams := &models.SearchModifierParameters{}
	if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("decoding parameters: %v", err)
	} else if searchResults, err := ds.SearchModifier(decodedParams); err != nil {
		return nil, nil, fmt.Errorf("executing query: %v", err)
	} else if jsonResults, err = json.Marshal(searchResults); err != nil {
		return nil, nil, fmt.Errorf("encoding results: %v", err)
	}
	return
}

// SearchModifier retrieves the info about or the children of the modifier identified by path.
func (ds I2b2DataSource) SearchModifier(params *models.SearchModifierParameters) (*models.SearchResults, error) {

	// make the appropriate request to i2b2
	path := strings.TrimSpace(params.Path)
	i2b2FormatPath := i2b2clientmodels.ConvertPathToI2b2Format(path)
	var resp *i2b2clientmodels.OntRespModifiersMessageBody
	var err error

	if len(path) == 0 {
		return nil, fmt.Errorf("empty path")
	}

	switch params.Operation {
	case "concept":
		if path == "/" {
			return &models.SearchResults{SearchResults: make([]models.SearchResult, 0)}, nil
		}

		req := i2b2clientmodels.NewOntReqGetModifiersMessageBody(i2b2FormatPath)
		if resp, err = ds.i2b2Client.OntGetModifiers(&req); err != nil {
			return nil, fmt.Errorf("requesting modifiers of concept: %v", err)
		}

	case "info":
		if path == "/" {
			return &models.SearchResults{SearchResults: make([]models.SearchResult, 0)}, nil
		}

		i2b2FormatAppliedPath := i2b2clientmodels.ConvertAppliedPathToI2b2Format(strings.TrimSpace(params.AppliedPath))
		req := i2b2clientmodels.NewOntReqGetModifierInfoMessageBody(i2b2FormatPath, i2b2FormatAppliedPath)
		if resp, err = ds.i2b2Client.OntGetModifierInfo(&req); err != nil {
			return nil, fmt.Errorf("requesting info of modifier: %v", err)
		}

	case "children":
		if path == "/" {
			return &models.SearchResults{SearchResults: make([]models.SearchResult, 0)}, nil
		}

		i2b2FormatAppliedPath := i2b2clientmodels.ConvertAppliedPathToI2b2Format(strings.TrimSpace(params.AppliedPath))
		i2b2FormatAppliedConcept := i2b2clientmodels.ConvertPathToI2b2Format(strings.TrimSpace(params.AppliedConcept))
		req := i2b2clientmodels.NewOntReqGetModifierChildrenMessageBody(ds.i2b2OntMaxElements, i2b2FormatPath, i2b2FormatAppliedPath, i2b2FormatAppliedConcept)
		if resp, err = ds.i2b2Client.OntGetModifierChildren(&req); err != nil {
			return nil, fmt.Errorf("requesting children of modifier: %v", err)
		}

	default:
		return nil, fmt.Errorf("invalid search operation: %v", params.Operation)
	}

	// generate result from response
	searchResults := make([]models.SearchResult, 0, len(resp.Modifiers))
	for _, modifier := range resp.Modifiers {
		searchResults = append(searchResults, models.NewSearchResultFromI2b2Modifier(modifier))
	}
	return &models.SearchResults{SearchResults: searchResults}, nil
}
