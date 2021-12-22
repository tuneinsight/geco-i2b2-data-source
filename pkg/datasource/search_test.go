package datasource

import (
	"testing"

	"github.com/ldsec/geco-i2b2-data-source/pkg/datasource/models"
	"github.com/stretchr/testify/require"
)

func TestSearchConceptInfo(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	searchResults, err := ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/",
		Operation: "info",
	})
	require.NoError(t, err)
	require.Empty(t, searchResults.SearchResults)

	searchResults, err = ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/TEST/test/",
		Operation: "info",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Equal(t, 1, len(searchResults.SearchResults))
	require.Contains(t, searchResults.SearchResults[0].Path, "/TEST/test/")

	searchResults, err = ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/TEST/test/1",
		Operation: "info",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Equal(t, 1, len(searchResults.SearchResults))
	require.Contains(t, searchResults.SearchResults[0].Path, "/TEST/test/1")
}

func TestSearchConceptChildren(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	searchResults, err := ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/",
		Operation: "children",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Equal(t, 1, len(searchResults.SearchResults))
	require.Contains(t, searchResults.SearchResults[0].Path, "/TEST/test/")

	searchResults, err = ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/TEST/test/",
		Operation: "children",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Equal(t, 3, len(searchResults.SearchResults))
	require.Contains(t, searchResults.SearchResults[0].Path, "/TEST/test/")

	searchResults, err = ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/TEST/test/2",
		Operation: "children",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Empty(t, searchResults.SearchResults)
}

func TestSearchConceptError(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	_, err := ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "",
		Operation: "children",
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "empty path")

	_, err = ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/TEST/test/",
		Operation: "xxxxxx",
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "invalid search operation")

	_, err = ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/TEST/test/4433",
		Operation: "children",
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "error")
}

func TestSearchModifierConcept(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	searchResults, err := ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/test/1/",
			Operation: "concept",
		},
		AppliedPath:    "",
		AppliedConcept: "",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Equal(t, 1, len(searchResults.SearchResults))
	require.Contains(t, searchResults.SearchResults[0].Path, "/TEST/modifiers/")

	searchResults, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/test/2/",
			Operation: "concept",
		},
		AppliedPath:    "",
		AppliedConcept: "",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Equal(t, 2, len(searchResults.SearchResults))
	require.Contains(t, searchResults.SearchResults[0].Path, "/TEST/modifiers/2")
	require.Contains(t, searchResults.SearchResults[1].Path, "/TEST/modifiers/2")
}

func TestSearchModifierInfo(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	searchResults, err := ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers/",
			Operation: "info",
		},
		AppliedPath: "/test/%",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Equal(t, 1, len(searchResults.SearchResults))
	require.Contains(t, searchResults.SearchResults[0].Path, "/TEST/modifiers/")

	searchResults, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers/1",
			Operation: "info",
		},
		AppliedPath: "/test/%",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Equal(t, 1, len(searchResults.SearchResults))
	require.Contains(t, searchResults.SearchResults[0].Path, "/TEST/modifiers/1")
}

func TestSearchModifierChildren(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	searchResults, err := ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers/",
			Operation: "children",
		},
		AppliedPath:    "/test/%",
		AppliedConcept: "/TEST/test/1/",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Equal(t, 1, len(searchResults.SearchResults))
	require.Contains(t, searchResults.SearchResults[0].Path, "/TEST/modifiers/1/")

	searchResults, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers/",
			Operation: "children",
		},
		AppliedPath:    "/test/%",
		AppliedConcept: "/TEST/test/2/",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Equal(t, 2, len(searchResults.SearchResults))

	searchResults, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers/",
			Operation: "children",
		},
		AppliedPath:    "/test/%",
		AppliedConcept: "/TEST/test/3/",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResults)
	require.Equal(t, 2, len(searchResults.SearchResults))
}

func TestSearchModifierError(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	_, err := ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "",
			Operation: "children",
		},
		AppliedPath:    "/test/%",
		AppliedConcept: "/TEST/test/3/",
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "empty path")

	_, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers/",
			Operation: "xxxxx",
		},
		AppliedPath:    "/test/%",
		AppliedConcept: "/TEST/test/3/",
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "invalid search operation")

	_, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers/",
			Operation: "children",
		},
		AppliedPath:    "/test",
		AppliedConcept: "/TEST/test/3/",
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "error")
}
