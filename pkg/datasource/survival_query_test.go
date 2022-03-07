package datasource

import (
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"

	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/models"
)

func TestSurvivalQuery(t *testing.T) {

	params := &models.SurvivalQueryParameters{
		ID:            "test-survival-query-weeks",
		CohortName:    "survival-test-cohort",
		CohortQueryID: "55555555-5555-5555-5555-555555555555",
		EndConcept:    "/SPHN/SPHNv2020.1/DeathStatus/",
		EndModifier: &models.SurvivalQueryModifier{
			AppliedPath: "/SPHNv2020.1/DeathStatus/",
			ModifierKey: "/SPHN/DeathStatus-status/death/",
		},
		EndsWhen:     models.WhenEarliest,
		StartConcept: "/SPHN/SPHNv2020.1/FophDiagnosis/",
		StartsWhen:   models.WhenEarliest,
		TimeLimit:    6,
	}

	t.Run("Survival_analysis_day", func(t *testing.T) {
		ds := getDataSource(t)
		defer dataSourceCleanUp(t, ds)

		params.TimeGranularity = "day"

		initialCounts, eventsOfInterestCounts, censoringEventsCounts, err := ds.SurvivalQuery("testuser1", params)
		logrus.Infof("initialCounts = %d, eventsOfInterestCounts = %v, censoringEventsCounts = %v", initialCounts, eventsOfInterestCounts, censoringEventsCounts)
		require.NoError(t, err)
		require.Equal(t, initialCounts, []int64{228})
		require.Equal(t, eventsOfInterestCounts, []int64{0, 0, 0, 0, 0, 1})
		require.Equal(t, censoringEventsCounts, []int64{0, 0, 0, 0, 0, 0})

	})

	t.Run("Survival_analysis_week", func(t *testing.T) {
		ds := getDataSource(t)
		defer dataSourceCleanUp(t, ds)

		params.TimeGranularity = "week"

		initialCounts, eventsOfInterestCounts, censoringEventsCounts, err := ds.SurvivalQuery("testuser1", params)
		logrus.Infof("initialCounts = %d, eventsOfInterestCounts = %v, censoringEventsCounts = %v", initialCounts, eventsOfInterestCounts, censoringEventsCounts)
		require.NoError(t, err)
		require.Equal(t, initialCounts, []int64{228})
		require.Equal(t, eventsOfInterestCounts, []int64{0, 1, 6, 1, 1, 2})
		require.Equal(t, censoringEventsCounts, []int64{0, 0, 0, 0, 0, 0})

	})

	t.Run("Survival_analysis_month", func(t *testing.T) {
		ds := getDataSource(t)
		defer dataSourceCleanUp(t, ds)

		params.TimeGranularity = "month"

		initialCounts, eventsOfInterestCounts, censoringEventsCounts, err := ds.SurvivalQuery("testuser1", params)
		logrus.Infof("initialCounts = %d, eventsOfInterestCounts = %v, censoringEventsCounts = %v", initialCounts, eventsOfInterestCounts, censoringEventsCounts)
		require.NoError(t, err)
		require.Equal(t, initialCounts, []int64{228})
		require.Equal(t, eventsOfInterestCounts, []int64{0, 10, 7, 10, 10, 10})
		require.Equal(t, censoringEventsCounts, []int64{0, 0, 0, 0, 2, 0})

	})

	t.Run("Survival_analysis_year", func(t *testing.T) {
		ds := getDataSource(t)
		defer dataSourceCleanUp(t, ds)

		params.TimeGranularity = "year"

		initialCounts, eventsOfInterestCounts, censoringEventsCounts, err := ds.SurvivalQuery("testuser1", params)
		logrus.Infof("initialCounts = %d, eventsOfInterestCounts = %v, censoringEventsCounts = %v", initialCounts, eventsOfInterestCounts, censoringEventsCounts)
		require.NoError(t, err)
		require.Equal(t, initialCounts, []int64{228})
		require.Equal(t, eventsOfInterestCounts, []int64{0, 121, 38, 6, 0, 0})
		require.Equal(t, censoringEventsCounts, []int64{0, 42, 14, 7, 0, 0})

	})

	t.Run("Survival_analysis_subgroups", func(t *testing.T) {
		ds := getDataSource(t)
		defer dataSourceCleanUp(t, ds)

		params.TimeGranularity = "week"
		params.SubGroupsDefinitions = []*models.SubGroupDefinition{
			{
				Name: "Female",
				Panels: []models.Panel{
					{
						Not:    false,
						Timing: "any",
						ConceptItems: []models.ConceptItem{
							{
								QueryTerm: "/I2B2/I2B2/Demographics/Gender/Female/",
							},
						},
					},
				},
				Timing: "any",
			},
			{
				Name: "Male",
				Panels: []models.Panel{
					{
						Not:    false,
						Timing: "any",
						ConceptItems: []models.ConceptItem{
							{
								QueryTerm: "/I2B2/I2B2/Demographics/Gender/Male/",
							},
						},
					},
				},
				Timing: "any",
			},
		}

		initialCounts, eventsOfInterestCounts, censoringEventsCounts, err := ds.SurvivalQuery("testuser1", params)
		logrus.Infof("initialCounts = %d, eventsOfInterestCounts = %v, censoringEventsCounts = %v", initialCounts, eventsOfInterestCounts, censoringEventsCounts)
		require.NoError(t, err)
		require.Equal(t, initialCounts, []int64{138, 90})
		require.Equal(t, eventsOfInterestCounts, []int64{0, 0, 6, 1, 1, 2, 0, 1, 0, 0, 0, 0})
		require.Equal(t, censoringEventsCounts, []int64{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})

	})

}
