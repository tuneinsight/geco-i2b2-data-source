package datasource

import (
	"fmt"
	"testing"

	"github.com/ldsec/geco-i2b2-data-source/pkg/datasource/models"
	gecomodels "github.com/ldsec/geco/pkg/models"
	gecosdk "github.com/ldsec/geco/pkg/sdk"
	"github.com/stretchr/testify/require"
)

func TestExploreQueryConcept(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	_, count, patientList, err := ds.ExploreQuery(&models.ExploreQueryParameters{
		ID: "0",
		Definition: models.ExploreQueryDefinition{
			Panels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/1/",
				}},
			}},
		},
	})
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 3, count)
	require.Subset(t, []int64{1, 2, 3}, patientList)

	_, count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		ID: "1",
		Definition: models.ExploreQueryDefinition{
			Panels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/3/",
				}},
			}},
		},
	})
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 4, count)
	require.Subset(t, []int64{1, 2, 3, 4}, patientList)

	_, count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		ID: "2",
		Definition: models.ExploreQueryDefinition{
			Panels: []models.Panel{{
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
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 3, count)
	require.Subset(t, []int64{1, 2, 3}, patientList)

	_, count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		ID: "3",
		Definition: models.ExploreQueryDefinition{
			Panels: []models.Panel{{
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
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 4, count)
	require.Subset(t, []int64{1, 2, 3, 4}, patientList)
}

func TestExploreQueryConceptValue(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	_, count, patientList, err := ds.ExploreQuery(&models.ExploreQueryParameters{
		ID: "0",
		Definition: models.ExploreQueryDefinition{
			Panels: []models.Panel{{
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
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 1, count)
	require.Subset(t, []int64{1}, patientList)

	_, count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		ID: "1",
		Definition: models.ExploreQueryDefinition{
			Panels: []models.Panel{{
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
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 2, count)
	require.Subset(t, []int64{1, 4}, patientList)
}

func TestExploreQueryModifier(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	_, count, patientList, err := ds.ExploreQuery(&models.ExploreQueryParameters{
		ID: "0",
		Definition: models.ExploreQueryDefinition{
			Panels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/1/",
					Modifier: struct {
						Key         string
						AppliedPath string
					}{
						Key:         "/TEST/modifiers/1/",
						AppliedPath: "/test/1/",
					},
				}},
			}},
		},
	})
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 2, count)
	require.Subset(t, []int64{1, 3}, patientList)

	_, count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		ID: "1",
		Definition: models.ExploreQueryDefinition{
			Panels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/1/",
					Modifier: struct {
						Key         string
						AppliedPath string
					}{
						Key:         "/TEST/modifiers/1/",
						AppliedPath: "/test/1/",
					},
				}, {
					QueryTerm: "/TEST/test/2/",
					Modifier: struct {
						Key         string
						AppliedPath string
					}{
						Key:         "/TEST/modifiers/2text/",
						AppliedPath: "/test/2/",
					},
				}},
			}},
		},
	})
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 3, count)
	require.Subset(t, []int64{1, 2, 3}, patientList)
}

func TestExploreQueryModifierValue(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	_, count, patientList, err := ds.ExploreQuery(&models.ExploreQueryParameters{
		ID: "0",
		Definition: models.ExploreQueryDefinition{
			Panels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/2/",
					Operator:  "LIKE[contains]",
					Value:     "cd",
					Type:      "TEXT",
					Modifier: struct {
						Key         string
						AppliedPath string
					}{
						Key:         "/TEST/modifiers/2text/",
						AppliedPath: "/test/2/",
					},
				}},
			}},
		},
	})
	require.NoError(t, err)
	t.Logf("results: count=%v, patientList=%v", count, patientList)
	require.EqualValues(t, 1, count)
	require.Subset(t, []int64{1}, patientList)

	_, count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		ID: "1",
		Definition: models.ExploreQueryDefinition{
			Panels: []models.Panel{{
				Not: false,
				ConceptItems: []models.ConceptItem{{
					QueryTerm: "/TEST/test/3/",
					Operator:  "LIKE[exact]",
					Value:     "def",
					Type:      "TEXT",
					Modifier: struct {
						Key         string
						AppliedPath string
					}{
						Key:         "/TEST/modifiers/3text/",
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
						Key         string
						AppliedPath string
					}{
						Key:         "/TEST/modifiers/2text/",
						AppliedPath: "/test/2/",
					},
				}},
			}},
		},
	})
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

	params := fmt.Sprintf(`{"id": "%v", "definition": {"panels": [{"conceptItems": [{"queryTerm": "/TEST/test/1/"}]}]}}`, queryID)
	sharedIDs := map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID{
		outputNameExploreQueryCount:       gecomodels.DataObjectSharedID(countSharedID),
		outputNameExploreQueryPatientList: gecomodels.DataObjectSharedID(patientListSharedID),
	}
	_, _, err := ds.Query("testUser", "exploreQuery", []byte(params), sharedIDs)
	require.NoError(t, err)

	query, err := ds.db.GetExploreQuery(queryID)
	require.NoError(t, err)
	require.EqualValues(t, "success", query.Status)
	require.EqualValues(t, countSharedID, query.ResultGecoSharedIDCount.String)
	require.EqualValues(t, patientListSharedID, query.ResultGecoSharedIDPatientList.String)
}
