package i2b2datasource

import (
	"testing"

	"github.com/ldsec/geco-i2b2-data-source/pkg/i2b2datasource/models"
	"github.com/stretchr/testify/require"
)

func TestExploreQueryConcept(t *testing.T) {
	ds := getTestDataSource(t)

	count, patientList, err := ds.ExploreQuery(&models.ExploreQueryParameters{
		Id: "0",
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
	require.Subset(t, []uint64{1, 2, 3}, patientList)

	count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		Id: "1",
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
	require.Subset(t, []uint64{1, 2, 3, 4}, patientList)

	count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		Id: "2",
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
	require.Subset(t, []uint64{1, 2, 3}, patientList)

	count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		Id: "3",
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
	require.Subset(t, []uint64{1, 2, 3, 4}, patientList)
}

func TestExploreQueryConceptValue(t *testing.T) {
	ds := getTestDataSource(t)

	count, patientList, err := ds.ExploreQuery(&models.ExploreQueryParameters{
		Id: "0",
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
	require.Subset(t, []uint64{1}, patientList)

	count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		Id: "1",
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
	require.Subset(t, []uint64{1, 4}, patientList)
}

func TestExploreQueryModifier(t *testing.T) {
	ds := getTestDataSource(t)

	count, patientList, err := ds.ExploreQuery(&models.ExploreQueryParameters{
		Id: "0",
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
	require.Subset(t, []uint64{1, 3}, patientList)

	count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		Id: "1",
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
	require.Subset(t, []uint64{1, 2, 3}, patientList)
}

func TestExploreQueryModifierValue(t *testing.T) {
	ds := getTestDataSource(t)

	count, patientList, err := ds.ExploreQuery(&models.ExploreQueryParameters{
		Id: "0",
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
	require.Subset(t, []uint64{1}, patientList)

	count, patientList, err = ds.ExploreQuery(&models.ExploreQueryParameters{
		Id: "1",
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
	require.Subset(t, []uint64{2}, patientList)
}
