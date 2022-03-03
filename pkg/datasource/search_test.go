package datasource

import (
	"testing"

	"github.com/stretchr/testify/require"
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/models"
)

func TestSearchConceptInfo(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	searchResults, err := ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/",
		Operation: "info",
	})
	require.NoError(t, err)
	require.Empty(t, searchResults.SearchResultElements)

	searchResults, err = ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/TEST/test/",
		Operation: "info",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 1, len(searchResults.SearchResultElements))
	require.Contains(t, searchResults.SearchResultElements[0].Path, "/TEST/test/")

	searchResults, err = ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/TEST/test/1",
		Operation: "info",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 1, len(searchResults.SearchResultElements))
	require.Contains(t, searchResults.SearchResultElements[0].Path, "/TEST/test/1")
}

func TestSearchConceptChildren(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	searchResults, err := ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/",
		Operation: "children",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 3, len(searchResults.SearchResultElements))
	require.Contains(t, searchResults.SearchResultElements[0].Path, "/I2B2/I2B2/")
	require.Contains(t, searchResults.SearchResultElements[1].Path, "/SPHN/SPHNv2020.1/")
	require.Contains(t, searchResults.SearchResultElements[2].Path, "/TEST/test/")

	searchResults, err = ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/TEST/test/",
		Operation: "children",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 3, len(searchResults.SearchResultElements))
	require.Contains(t, searchResults.SearchResultElements[0].Path, "/TEST/test/")

	searchResults, err = ds.SearchConcept(&models.SearchConceptParameters{
		Path:      "/TEST/test/2",
		Operation: "children",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 2, len(searchResults.SearchResultElements))
	require.Contains(t, searchResults.SearchResultElements[0].Path, "/TEST/modifiers2/2")
	require.Contains(t, searchResults.SearchResultElements[1].Path, "/TEST/modifiers2/text")
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
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 1, len(searchResults.SearchResultElements))
	require.Contains(t, searchResults.SearchResultElements[0].Path, "/TEST/modifiers1/")

	searchResults, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/test/2/",
			Operation: "concept",
		},
		AppliedPath:    "",
		AppliedConcept: "",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 2, len(searchResults.SearchResultElements))
	require.Contains(t, searchResults.SearchResultElements[0].Path, "/TEST/modifiers2/2")
	require.Contains(t, searchResults.SearchResultElements[1].Path, "/TEST/modifiers2/text")
}

func TestSearchModifierInfo(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	searchResults, err := ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers1/",
			Operation: "info",
		},
		AppliedPath: "/test/1/",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 1, len(searchResults.SearchResultElements))

	searchResults, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers1/1",
			Operation: "info",
		},
		AppliedPath: "/test/%",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 1, len(searchResults.SearchResultElements))
	require.Contains(t, searchResults.SearchResultElements[0].Path, "/TEST/modifiers1/1")
}

func TestSearchModifierChildren(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	searchResults, err := ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers1/",
			Operation: "children",
		},
		AppliedPath:    "/test/1/",
		AppliedConcept: "/TEST/test/1/",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 1, len(searchResults.SearchResultElements))
	require.Contains(t, searchResults.SearchResultElements[0].Path, "/TEST/modifiers1/1/")

	searchResults, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers2/",
			Operation: "children",
		},
		AppliedPath:    "/test/2/",
		AppliedConcept: "/TEST/test/2/",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 2, len(searchResults.SearchResultElements))

	searchResults, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers3/",
			Operation: "children",
		},
		AppliedPath:    "/test/3/",
		AppliedConcept: "/TEST/test/3/",
	})
	require.NoError(t, err)
	t.Logf("%+v", searchResults.SearchResultElements)
	require.Equal(t, 2, len(searchResults.SearchResultElements))
}

func TestSearchModifierError(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	_, err := ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "",
			Operation: "children",
		},
		AppliedPath:    "/test/3/",
		AppliedConcept: "/TEST/test/3/",
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "empty path")

	_, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers/3/",
			Operation: "xxxxx",
		},
		AppliedPath:    "/test/3/",
		AppliedConcept: "/TEST/test/3/",
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "invalid search operation")

	_, err = ds.SearchModifier(&models.SearchModifierParameters{
		SearchConceptParameters: models.SearchConceptParameters{
			Path:      "/TEST/modifiers3/",
			Operation: "children",
		},
		AppliedPath:    "/test",
		AppliedConcept: "/TEST/test/3/",
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "error")
}
