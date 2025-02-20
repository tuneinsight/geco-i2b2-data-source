package datasource

import (
	"encoding/json"
	"fmt"
	"strconv"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/models"
	gecomodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk"
	gecosdk "github.com/tuneinsight/sdk-datasource/pkg/sdk"
)

func TestExploreQueryConcept(t *testing.T) {

	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	patientSetID, count, err := ds.ExploreQuery("testuser1", &models.ExploreQueryParameters{
		ID: "0",
		Definition: models.ExploreQueryDefinition{
			SelectionPanels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/1/",
				}},
			}},
		},
	})
	require.NoError(t, err)
	patientList, err := ds.getPatientIDs(patientSetID)
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 3, count)
	require.Subset(t, []int64{1, 2, 3}, patientList)

	patientSetID, count, err = ds.ExploreQuery("testuser1", &models.ExploreQueryParameters{
		ID: "1",
		Definition: models.ExploreQueryDefinition{
			SelectionPanels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/3/",
				}},
			}},
		},
	})
	require.NoError(t, err)
	patientList, err = ds.getPatientIDs(patientSetID)
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 4, count)
	require.Subset(t, []int64{1, 2, 3, 4}, patientList)

	patientSetID, count, err = ds.ExploreQuery("testuser1", &models.ExploreQueryParameters{
		ID: "2",
		Definition: models.ExploreQueryDefinition{
			SelectionPanels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/1/",
				}},
			}, {
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/2/",
				}},
			}, {
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/3/",
				}},
			}},
		},
	})
	require.NoError(t, err)
	patientList, err = ds.getPatientIDs(patientSetID)
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 3, count)
	require.Subset(t, []int64{1, 2, 3}, patientList)

	patientSetID, count, err = ds.ExploreQuery("testuser1", &models.ExploreQueryParameters{
		ID: "3",
		Definition: models.ExploreQueryDefinition{
			SelectionPanels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/1/",
				}, {
					QueryTerm: "/TEST/test/3/",
				}},
			}},
		},
	})
	require.NoError(t, err)
	patientList, err = ds.getPatientIDs(patientSetID)
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 4, count)
	require.Subset(t, []int64{1, 2, 3, 4}, patientList)
}

func TestExploreQueryConceptValue(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	patientSetID, count, err := ds.ExploreQuery("testuser1", &models.ExploreQueryParameters{
		ID: "0",
		Definition: models.ExploreQueryDefinition{
			SelectionPanels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/1/",
					Operator:  "EQ",
					Value:     "10",
					Type:      "NUMBER",
				}},
			}},
		},
	})
	require.NoError(t, err)
	patientList, err := ds.getPatientIDs(patientSetID)
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 1, count)
	require.Subset(t, []int64{1}, patientList)

	patientSetID, count, err = ds.ExploreQuery("testuser1", &models.ExploreQueryParameters{
		ID: "1",
		Definition: models.ExploreQueryDefinition{
			SelectionPanels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/1/",
					Operator:  "EQ",
					Value:     "10",
					Type:      "NUMBER",
				}, {
					QueryTerm: "/TEST/test/3/",
					Operator:  "EQ",
					Value:     "20",
					Type:      "NUMBER",
				}},
			}},
		},
	})
	require.NoError(t, err)
	patientList, err = ds.getPatientIDs(patientSetID)
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 2, count)
	require.Subset(t, []int64{1, 4}, patientList)
}

func TestExploreQueryModifier(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	patientSetID, count, err := ds.ExploreQuery("testuser1", &models.ExploreQueryParameters{
		ID: "0",
		Definition: models.ExploreQueryDefinition{
			SelectionPanels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/1/",
					Modifier: struct {
						Key         string `json:"key"`
						AppliedPath string `json:"appliedPath"`
					}{
						Key:         "/TEST/modifiers1/1/",
						AppliedPath: "/test/1/",
					},
				}},
			}},
		},
	})
	require.NoError(t, err)
	patientList, err := ds.getPatientIDs(patientSetID)
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 2, count)
	require.Subset(t, []int64{1, 3}, patientList)

	patientSetID, count, err = ds.ExploreQuery("testuser1", &models.ExploreQueryParameters{
		ID: "1",
		Definition: models.ExploreQueryDefinition{
			SelectionPanels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/1/",
					Modifier: struct {
						Key         string `json:"key"`
						AppliedPath string `json:"appliedPath"`
					}{
						Key:         "/TEST/modifiers1/1/",
						AppliedPath: "/test/1/",
					},
				}, {
					QueryTerm: "/TEST/test/2/",
					Modifier: struct {
						Key         string `json:"key"`
						AppliedPath string `json:"appliedPath"`
					}{
						Key:         "/TEST/modifiers2/text/",
						AppliedPath: "/test/2/",
					},
				}},
			}},
		},
	})
	require.NoError(t, err)
	patientList, err = ds.getPatientIDs(patientSetID)
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 3, count)
	require.Subset(t, []int64{1, 2, 3}, patientList)
}

func TestExploreQueryModifierValue(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	patientSetID, count, err := ds.ExploreQuery("testuser1", &models.ExploreQueryParameters{
		ID: "0",
		Definition: models.ExploreQueryDefinition{
			SelectionPanels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/2/",
					Operator:  "LIKE[contains]",
					Value:     "cd",
					Type:      "TEXT",
					Modifier: struct {
						Key         string `json:"key"`
						AppliedPath string `json:"appliedPath"`
					}{
						Key:         "/TEST/modifiers2/text/",
						AppliedPath: "/test/2/",
					},
				}},
			}},
		},
	})
	require.NoError(t, err)
	patientList, err := ds.getPatientIDs(patientSetID)
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 1, count)
	require.Subset(t, []int64{1}, patientList)

	patientSetID, count, err = ds.ExploreQuery("testuser1", &models.ExploreQueryParameters{
		ID: "1",
		Definition: models.ExploreQueryDefinition{
			SelectionPanels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/3/",
					Operator:  "LIKE[exact]",
					Value:     "def",
					Type:      "TEXT",
					Modifier: struct {
						Key         string `json:"key"`
						AppliedPath string `json:"appliedPath"`
					}{
						Key:         "/TEST/modifiers3/text/",
						AppliedPath: "/test/3/",
					},
				}},
			}, {
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/2/",
					Operator:  "LIKE[begin]",
					Value:     "a",
					Type:      "TEXT",
					Modifier: struct {
						Key         string `json:"key"`
						AppliedPath string `json:"appliedPath"`
					}{
						Key:         "/TEST/modifiers2/text/",
						AppliedPath: "/test/2/",
					},
				}},
			}},
		},
	})
	require.NoError(t, err)
	patientList, err = ds.getPatientIDs(patientSetID)
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 1, count)
	require.Subset(t, []int64{2}, patientList)
}

func TestExploreQueryDatabase(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	queryID := "44444444-7777-4444-4444-444444444442"
	countSharedID := "44444444-7777-8888-4444-444444444444"
	patientListSharedID := "44444444-7777-4444-7121-444444444444"

	sharedIDs := map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID{
		outputNameExploreQueryCount:       gecomodels.DataObjectSharedID(countSharedID),
		outputNameExploreQueryPatientList: gecomodels.DataObjectSharedID(patientListSharedID),
	}
	jsonSharedIDs, _ := json.Marshal(sharedIDs)

	params := fmt.Sprintf(`{"id": "%v", "definition": {"selectionPanels": [{"conceptItems": [{"queryTerm": "/TEST/test/1/"}]}]},"outputDataObjectsSharedIDs": `+string(jsonSharedIDs)+`}`, queryID)
	_, err := ds.Query("testUser", map[string]interface{}{sdk.QueryOperation: "exploreQuery", sdk.QueryParams: params})
	require.NoError(t, err)

	query, err := ds.db.GetExploreQuery("testUser", queryID)
	require.NoError(t, err)
	require.EqualValues(t, "success", query.Status)
	require.EqualValues(t, countSharedID, query.ResultGecoSharedIDCount.String)
	require.EqualValues(t, patientListSharedID, query.ResultGecoSharedIDPatientList.String)
}

func TestExploreQueryWithSequence(t *testing.T) {

	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	patientSetID, patientCount, err := ds.ExploreQuery(
		"testUser",
		&models.ExploreQueryParameters{
			ID: "",
			Definition: models.ExploreQueryDefinition{
				Timing: models.TimingAny,
				SelectionPanels: []models.Panel{
					{ConceptItems: []models.ConceptItem{
						{
							QueryTerm: "/TEST/test/1/",
						},
					},
						Not: false,
					}},
				SequentialPanels: []models.Panel{
					{ConceptItems: []models.ConceptItem{
						{
							QueryTerm: "/TEST/test/1/",
						},
					},
						Not: false,
					},
					{ConceptItems: []models.ConceptItem{
						{
							QueryTerm: "/TEST/test/2/",
						},
					},
						Not: false,
					}},
				SequentialOperators: []models.SequentialOperator{
					{
						When:                   models.SequentialOperatorWhenLess,
						WhichDateFirst:         models.SequentialOperatorWhichDateStart,
						WhichDateSecond:        models.SequentialOperatorWhichDateStart,
						WhichObservationFirst:  models.SequentialOperatorWhichObservationFirst,
						WhichObservationSecond: models.SequentialOperatorWhichObservationFirst,
					}},
			},
		})

	assert.NoError(t, err)
	t.Log("count:"+strconv.FormatInt(patientCount, 10), "set ID:"+patientSetID, 10)

	// not a correct number of sequence panels for the number of sequence operators
	patientSetID, patientCount, err = ds.ExploreQuery(
		"testUser",
		&models.ExploreQueryParameters{
			ID: "",
			Definition: models.ExploreQueryDefinition{
				Timing: models.TimingAny,
				SequentialPanels: []models.Panel{
					{ConceptItems: []models.ConceptItem{
						{
							QueryTerm: "/TEST/test/1/",
						},
					},
						Not: false,
					}},
				SequentialOperators: []models.SequentialOperator{
					{
						When:                   models.SequentialOperatorWhenLess,
						WhichDateFirst:         models.SequentialOperatorWhichDateStart,
						WhichDateSecond:        models.SequentialOperatorWhichDateStart,
						WhichObservationFirst:  models.SequentialOperatorWhichObservationFirst,
						WhichObservationSecond: models.SequentialOperatorWhichObservationFirst,
					}},
			},
		})

	assert.Error(t, err)
	t.Log("count:"+strconv.FormatInt(patientCount, 10), "set ID:"+patientSetID)
}
