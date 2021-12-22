package datasource

import (
	"testing"

	"github.com/ldsec/geco-i2b2-data-source/pkg/datasource/models"
	"github.com/stretchr/testify/require"
)

func TestGetCohorts(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	cohorts, err := ds.GetCohorts("testuser2", &models.GetCohortsParameters{})
	require.NoError(t, err)
	require.EqualValues(t, 2, len(cohorts.Cohorts))
	require.EqualValues(t, "cohort4", cohorts.Cohorts[0].Name)
	require.EqualValues(t, "cohort3", cohorts.Cohorts[1].Name)

	cohorts, err = ds.GetCohorts("testuser2", &models.GetCohortsParameters{Limit: 1})
	require.NoError(t, err)
	require.EqualValues(t, 1, len(cohorts.Cohorts))
	require.EqualValues(t, "cohort4", cohorts.Cohorts[0].Name)
}

func TestAddCohort(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	err := ds.AddCohort("testuser1", &models.AddDeleteCohortParameters{
		Name:           "cohort0",
		ExploreQueryID: "00000000-0000-0000-0000-000000000000",
	})
	require.NoError(t, err)

	cohorts, err := ds.GetCohorts("testuser1", &models.GetCohortsParameters{})
	require.NoError(t, err)
	require.EqualValues(t, 2, len(cohorts.Cohorts))
	require.EqualValues(t, "cohort0", cohorts.Cohorts[0].Name)
	require.EqualValues(t, "cohort1", cohorts.Cohorts[1].Name)

	err = ds.AddCohort("testuser2", &models.AddDeleteCohortParameters{
		Name:           "cohort4bis",
		ExploreQueryID: "44444444-4444-4444-4444-444444444444",
	})
	require.NoError(t, err)

	cohorts, err = ds.GetCohorts("testuser2", &models.GetCohortsParameters{})
	require.NoError(t, err)
	require.EqualValues(t, 3, len(cohorts.Cohorts))
	require.EqualValues(t, "cohort4bis", cohorts.Cohorts[0].Name)
	require.EqualValues(t, "cohort4", cohorts.Cohorts[1].Name)
	require.EqualValues(t, "cohort3", cohorts.Cohorts[2].Name)
}

func TestDeleteCohort(t *testing.T) {
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	err := ds.DeleteCohort("testuser1", &models.AddDeleteCohortParameters{
		Name:           "cohort1",
		ExploreQueryID: "11111111-1111-1111-1111-111111111111",
	})
	require.NoError(t, err)

	cohorts, err := ds.GetCohorts("testuser1", &models.GetCohortsParameters{})
	require.NoError(t, err)
	require.EqualValues(t, 0, len(cohorts.Cohorts))

	err = ds.DeleteCohort("testuser2", &models.AddDeleteCohortParameters{
		Name:           "cohort4",
		ExploreQueryID: "44444444-4444-4444-4444-444444444444",
	})
	require.NoError(t, err)

	cohorts, err = ds.GetCohorts("testuser2", &models.GetCohortsParameters{})
	require.NoError(t, err)
	require.EqualValues(t, 1, len(cohorts.Cohorts))
	require.EqualValues(t, "cohort3", cohorts.Cohorts[0].Name)
}
