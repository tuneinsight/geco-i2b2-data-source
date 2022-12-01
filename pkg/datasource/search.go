package datasource

import (
	"encoding/json"
	"encoding/xml"
	"fmt"
	"strings"

	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/models"
	i2b2clientmodels "github.com/tuneinsight/geco-i2b2-data-source/pkg/i2b2client/models"
	gecomodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	gecosdk "github.com/tuneinsight/sdk-datasource/pkg/sdk"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk/telemetry"
)

// SearchConceptHandler is the OperationHandler for the OperationSearchConcept Operation.
func (ds *I2b2DataSource) SearchConceptHandler(_ string, jsonParameters []byte, _ map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID) (jsonResults []byte, _ []gecosdk.DataObject, err error) {
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

// SearchConcept retrieves the info about or the children of the concept identified by the params.
func (ds *I2b2DataSource) SearchConcept(params *models.SearchConceptParameters) (*models.SearchResult, error) {

	span := telemetry.StartSpan(ds.Ctx, "datasource:i2b2", "SearchConcept")
	defer span.End()

	// make the appropriate request to i2b2
	path := strings.TrimSpace(params.Path)
	i2b2FormatPath := i2b2clientmodels.ConvertPathToI2b2Format(path)
	var respConcepts *i2b2clientmodels.OntRespConceptsMessageBody
	respModifiers := new(models.SearchResult)

	var err error

	if len(path) == 0 {
		return nil, fmt.Errorf("empty path")
	}

	if params.Limit == "" {
		params.Limit = ds.i2b2Config.OntMaxElements
	} else if params.Limit == "0" {
		params.Limit = ""
	}

	switch params.Operation {
	case models.SearchInfoOperation:
		if path == "/" {
			return &models.SearchResult{SearchResultElements: make([]*models.SearchResultElement, 0)}, nil
		}

		req := i2b2clientmodels.NewOntReqGetTermInfoMessageBody(params.Limit, i2b2FormatPath)
		if respConcepts, err = ds.i2b2Client.OntGetTermInfo(&req); err != nil {
			return nil, fmt.Errorf("requesting term info: %v", err)
		}

	case models.SearchChildrenOperation:
		if path == "/" {
			req := i2b2clientmodels.NewOntReqGetCategoriesMessageBody()
			if respConcepts, err = ds.i2b2Client.OntGetCategories(&req); err != nil {
				return nil, fmt.Errorf("requesting categories: %v", err)
			}
			break
		}

		req := i2b2clientmodels.NewOntReqGetChildrenMessageBody(params.Limit, i2b2FormatPath)
		if respConcepts, err = ds.i2b2Client.OntGetChildren(&req); err != nil {
			return nil, fmt.Errorf("requesting children (concepts): %v", err)
		} else if respModifiers, err = ds.SearchModifier(&models.SearchModifierParameters{
			SearchConceptParameters: models.SearchConceptParameters{
				Path:      params.Path,
				Operation: "concept",
			},
		}); err != nil {
			return nil, fmt.Errorf("requesting children (modifiers): %v", err)
		}

	default:
		return nil, fmt.Errorf("invalid search operation: %v", params.Operation)
	}

	// generate result from response
	searchResultElements := make([]*models.SearchResultElement, 0, len(respConcepts.Concepts))
	for _, concept := range respConcepts.Concepts {
		searchResultElements = append(searchResultElements, models.NewSearchResultFromI2b2Concept(concept))
	}
	searchResultElements = append(searchResultElements, respModifiers.SearchResultElements...)
	return &models.SearchResult{SearchResultElements: searchResultElements}, nil
}

// SearchModifierHandler is the OperationHandler for the OperationSearchModifier Operation.
func (ds *I2b2DataSource) SearchModifierHandler(_ string, jsonParameters []byte, _ map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID) (jsonResults []byte, _ []gecosdk.DataObject, err error) {
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

// SearchModifier retrieves the info about or the children of the modifier identified by params.
func (ds *I2b2DataSource) SearchModifier(params *models.SearchModifierParameters) (*models.SearchResult, error) {

	// make the appropriate request to i2b2
	path := strings.TrimSpace(params.Path)
	i2b2FormatPath := i2b2clientmodels.ConvertPathToI2b2Format(path)
	var resp *i2b2clientmodels.OntRespModifiersMessageBody
	var err error

	if len(path) == 0 {
		return nil, fmt.Errorf("empty path")
	}

	if params.Limit == "" {
		params.Limit = ds.i2b2Config.OntMaxElements
	} else if params.Limit == "0" {
		params.Limit = ""
	}

	switch params.Operation {
	case models.SearchConceptOperation:
		if path == "/" {
			return &models.SearchResult{SearchResultElements: make([]*models.SearchResultElement, 0)}, nil
		}

		req := i2b2clientmodels.NewOntReqGetModifiersMessageBody(i2b2FormatPath)
		if resp, err = ds.i2b2Client.OntGetModifiers(&req); err != nil {
			return nil, fmt.Errorf("requesting modifiers of concept: %v", err)
		}

	case models.SearchInfoOperation:
		if path == "/" {
			return &models.SearchResult{SearchResultElements: make([]*models.SearchResultElement, 0)}, nil
		}

		i2b2FormatAppliedPath := i2b2clientmodels.ConvertAppliedPathToI2b2Format(strings.TrimSpace(params.AppliedPath))
		req := i2b2clientmodels.NewOntReqGetModifierInfoMessageBody(i2b2FormatPath, i2b2FormatAppliedPath)
		if resp, err = ds.i2b2Client.OntGetModifierInfo(&req); err != nil {
			return nil, fmt.Errorf("requesting info of modifier: %v", err)
		}

	case models.SearchChildrenOperation:
		if path == "/" {
			return &models.SearchResult{SearchResultElements: make([]*models.SearchResultElement, 0)}, nil
		}

		i2b2FormatAppliedPath := i2b2clientmodels.ConvertAppliedPathToI2b2Format(strings.TrimSpace(params.AppliedPath))
		i2b2FormatAppliedConcept := i2b2clientmodels.ConvertPathToI2b2Format(strings.TrimSpace(params.AppliedConcept))
		req := i2b2clientmodels.NewOntReqGetModifierChildrenMessageBody(params.Limit, i2b2FormatPath, i2b2FormatAppliedPath, i2b2FormatAppliedConcept)
		if resp, err = ds.i2b2Client.OntGetModifierChildren(&req); err != nil {
			return nil, fmt.Errorf("requesting children of modifier: %v", err)
		}

	default:
		return nil, fmt.Errorf("invalid search operation: %v", params.Operation)
	}

	// generate result from response
	searchResults := make([]*models.SearchResultElement, 0, len(resp.Modifiers))
	for _, modifier := range resp.Modifiers {
		searchResults = append(searchResults, models.NewSearchResultFromI2b2Modifier(modifier))
	}
	return &models.SearchResult{SearchResultElements: searchResults}, nil
}

// SearchOntologyHandler is the OperationHandler for the OperationSearchOntology Operation.
func (ds *I2b2DataSource) SearchOntologyHandler(_ string, jsonParameters []byte, _ map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID) (jsonResults []byte, _ []gecosdk.DataObject, err error) {
	decodedParams := &models.SearchOntologyParameters{}
	if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("decoding parameters: %v", err)
	} else if searchResults, err := ds.SearchOntology(decodedParams); err != nil {
		return nil, nil, fmt.Errorf("executing query: %v", err)
	} else if jsonResults, err = json.Marshal(searchResults); err != nil {
		return nil, nil, fmt.Errorf("encoding results: %v", err)
	}
	return
}

// SearchOntology retrieves the info about the concepts and modifiers identified by params.
func (ds *I2b2DataSource) SearchOntology(params *models.SearchOntologyParameters) (*models.SearchResult, error) {

	if len(*params.SearchString) == 0 {
		return nil, fmt.Errorf("empty search string")
	}

	ontologyElements, err := ds.db.SearchOntology(*params.SearchString, params.Limit)
	if err != nil {
		return nil, fmt.Errorf("while searching ontology: %v", err)
	}

	currentID := 0
	results := make([]*models.SearchResultElement, 0)
	var currentElement *models.SearchResultElement

	for _, ontologyElement := range ontologyElements {

		ontologyElementParsed := i2b2clientmodels.OntologyElement{
			Key:              ontologyElement.FullName,
			Name:             ontologyElement.Name,
			Visualattributes: ontologyElement.VisualAttributes,
			Basecode:         ontologyElement.BaseCode,
			AppliedPath:      ontologyElement.AppliedPath,
		}

		if ontologyElement.MetaDataXML.Valid {
			ontologyElementParsed.Metadataxml = new(i2b2clientmodels.MetadataXML)
			err = xml.Unmarshal([]byte(ontologyElement.MetaDataXML.String), ontologyElementParsed.Metadataxml)
			if err != nil {
				return nil, fmt.Errorf("while unmarshalling xml metadata of ontology element %s: %v", ontologyElement.FullName, err)
			}
		}

		if ontologyElement.Comment.Valid {
			ontologyElementParsed.Comment = ontologyElement.Comment.String
		}

		searchResultElement := models.NewSearchResultFromI2b2OntologyElement(ontologyElementParsed)

		// a found element and its ancestors have the same ID (ID starts from 1)
		// the result of the query is ordered, i.e. element at position i have its father at position i+1
		if ontologyElement.ID != currentID {
			currentID = ontologyElement.ID
			results = append(results, searchResultElement)
		} else {
			currentElement.Parent = searchResultElement
		}

		currentElement = searchResultElement

	}

	return &models.SearchResult{SearchResultElements: results}, nil
}
