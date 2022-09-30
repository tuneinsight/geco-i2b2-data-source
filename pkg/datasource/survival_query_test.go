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
	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	t.Run("Survival_analysis_day", func(t *testing.T) {

		params.TimeGranularity = "day"

		survivalQueryResult, err := ds.SurvivalQuery("testuser1", params)
		logrus.Infof("survivalQueryResult = %v", survivalQueryResult)
		require.NoError(t, err)
		require.Equal(t, survivalQueryResult, []int64{228, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0})

	})

	t.Run("Survival_analysis_week", func(t *testing.T) {

		params.TimeGranularity = "week"

		survivalQueryResult, err := ds.SurvivalQuery("testuser1", params)
		logrus.Infof("survivalQueryResult = %v", survivalQueryResult)
		require.NoError(t, err)
		require.Equal(t, survivalQueryResult, []int64{228, 0, 0, 1, 0, 6, 0, 1, 0, 1, 0, 2, 0})

	})

	t.Run("Survival_analysis_month", func(t *testing.T) {

		params.TimeGranularity = "month"

		survivalQueryResult, err := ds.SurvivalQuery("testuser1", params)
		logrus.Infof("survivalQueryResult = %v", survivalQueryResult)
		require.NoError(t, err)
		require.Equal(t, survivalQueryResult, []int64{228, 0, 0, 10, 0, 7, 0, 10, 0, 10, 2, 10, 0})

	})

	t.Run("Survival_analysis_year", func(t *testing.T) {

		params.TimeGranularity = "year"

		survivalQueryResult, err := ds.SurvivalQuery("testuser1", params)
		logrus.Infof("survivalQueryResult = %v", survivalQueryResult)
		require.NoError(t, err)
		require.Equal(t, survivalQueryResult, []int64{228, 0, 0, 121, 42, 38, 14, 6, 7, 0, 0, 0, 0})

	})

	t.Run("Survival_analysis_subgroups", func(t *testing.T) {

		params.TimeGranularity = "week"
		params.SubGroupsDefinitions = []*models.SubGroupDefinition{
			{
				Name: "Female",
				Constraint: models.ExploreQueryDefinition{
					Timing: models.TimingAny,
					SelectionPanels: []models.Panel{
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
				},
			},
			{
				Name: "Male",
				Constraint: models.ExploreQueryDefinition{
					Timing: models.TimingAny,
					SelectionPanels: []models.Panel{
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
				},
			},
		}

		survivalQueryResult, err := ds.SurvivalQuery("testuser1", params)
		logrus.Infof("survivalQueryResult = %v", survivalQueryResult)
		require.NoError(t, err)
		require.Equal(t, survivalQueryResult, []int64{138, 0, 0, 0, 0, 6, 0, 1, 0, 1, 0, 2, 0, 90, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0})

	})

}
