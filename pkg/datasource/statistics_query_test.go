package datasource

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/stretchr/testify/assert"
	dbmodels "github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/database"
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/models"
)

func TestProcessObservations(t *testing.T) {

	ds := getDataSource(t)
	defer dataSourceCleanUp(t, ds)

	t.Run("process_observations_1", func(t *testing.T) {
		params := models.StatisticsQueryParameters{
			BucketSize:      1,
			MinObservations: 0,
		}

		statsObservations := newStatsObservations([]float64{
			1, 1.5, 1.7,
			2.354, 2.65,
			3, 3.3, 3.6, 3.8,
		})

		counts, _, err := ds.processObservations(statsObservations, params.MinObservations, params.BucketSize)
		require.NoError(t, err)

		assert.EqualValues(t, 4, len(counts))

		assert.EqualValues(t, 0, counts[0]) //[0, 1[
		assert.EqualValues(t, 3, counts[1]) //[1, 2[
		assert.EqualValues(t, 2, counts[2]) //[2, 3[
		assert.EqualValues(t, 4, counts[3]) //[3, 4[
	})

	t.Run("process_observations_2", func(t *testing.T) {
		params := models.StatisticsQueryParameters{
			BucketSize:      1.5,
			MinObservations: 0,
		}

		statsObservations := newStatsObservations([]float64{
			0, .3, .6, .9, 1, 1.2,
			1.5, 1.7, 2.5, 2.354, 2.65,
			3, 3.3, 3.6, 3.8,
		})

		counts, _, err := ds.processObservations(statsObservations, params.MinObservations, params.BucketSize)
		require.NoError(t, err)

		assert.EqualValues(t, 3, len(counts))

		assert.EqualValues(t, 6, counts[0]) //[0, 1.5[
		assert.EqualValues(t, 5, counts[1]) //[1.5, 3[
		assert.EqualValues(t, 4, counts[2]) //[3, 4.5[
	})

	t.Run("process_observations_3", func(t *testing.T) {

		params := models.StatisticsQueryParameters{
			BucketSize:      2,
			MinObservations: 1,
		}

		statsObservations := newStatsObservations([]float64{
			0, .3, .6, .9, //ignored in principle
			1.5, 2.9,
			4.3, 3.3, 3.1,
		})

		counts, _, err := ds.processObservations(statsObservations, params.MinObservations, params.BucketSize)
		require.NoError(t, err)

		assert.EqualValues(t, 2, len(counts))

		assert.EqualValues(t, 2, counts[0]) //[1, 3[
		assert.EqualValues(t, 3, counts[1]) //[3, 5[
	})

	t.Run("process_observations_4", func(t *testing.T) {

		params := models.StatisticsQueryParameters{
			BucketSize:      1,
			MinObservations: -3,
		}

		statsObservations := newStatsObservations([]float64{
			-3, -2.5, -2.1, //[-3, -2[
			//[-2, -1[
			-1, -.5, //[-1, 0[
			0.1, 0.6, 0.72134243, 0.81, //[0, 1[
		})

		counts, _, err := ds.processObservations(statsObservations, params.MinObservations, params.BucketSize)
		require.NoError(t, err)

		assert.EqualValues(t, 4, len(counts))

		assert.EqualValues(t, 3, counts[0]) //[-3, -2[
		assert.EqualValues(t, 0, counts[1]) //[-2, -1[
		assert.EqualValues(t, 2, counts[2]) //[-1, 0[
		assert.EqualValues(t, 4, counts[3]) //[0, 1[
	})

}

//to generate sample with specific sample std and sample mean: https://stackoverflow.com/questions/51515423/generate-sample-data-with-an-exact-mean-and-standard-deviation
func TestOutlierRemoval(t *testing.T) {

	t.Run("outlier_removal_normal_0_mean_1_std", func(t *testing.T) {

		observations := []float64{
			0.7084059931947092, -1.3938866529750165, 0.8381589889349612, -0.15854619536495415, -1.648164911610732, -0.6054119313504469, 0.4572723633358847, 0.4186652857269435, -0.24690588110536288, -2.2574927403514495, 0.13992139803328693, 1.2442811370376787, 0.8162841137009632, 0.44723107362341913, 1.1804799163129334, 0.09032358192615982, 1.742408910847399, -0.9388871506088993, -0.19148360032025327, -0.6426536989872252,
		}
		outliers := []float64{3.4, 7, 9, -4, -3.1, -1000}

		mean_val := 0.
		std_val := 1.
		outlierRemovalTester(t, mean_val, std_val, outliers, observations)

	})

	t.Run("outlier_removal_normal_3_mean_5_std", func(t *testing.T) {

		observations := []float64{
			0.7084059931947092, -1.3938866529750165, 0.8381589889349612, -0.15854619536495415, -1.648164911610732, -0.6054119313504469, 0.4572723633358847, 0.4186652857269435, -0.24690588110536288, -2.2574927403514495, 0.13992139803328693, 1.2442811370376787, 0.8162841137009632, 0.44723107362341913, 1.1804799163129334, 0.09032358192615982, 1.742408910847399, -0.9388871506088993, -0.19148360032025327, -0.6426536989872252,
		}
		outliers := []float64{3.4, 7, 9, -4, -3.1, -1000}

		mean_val := 0.
		std_val := 1.
		outlierRemovalTester(t, mean_val, std_val, outliers, observations)

	})

}

func newStatsObservations(observations []float64) (queryResults []dbmodels.StatsObservation) {
	queryResults = make([]dbmodels.StatsObservation, 0)
	for i := 0; i < len(observations); i++ {
		queryResults = append(queryResults,
			dbmodels.StatsObservation{
				NumericValue:  observations[i],
				Unit:          "a",
				PatientNumber: int64(i),
			},
		)
	}
	return
}

//to generate sample with specific sample std and sample mean: https://stackoverflow.com/questions/51515423/generate-sample-data-with-an-exact-mean-and-standard-deviation
func TestOutlierRemovalNormal0Mean1Std(t *testing.T) {
	observations := []float64{
		-4.504332807814968, -3.588438949993705, -1.4253477722082, 4.481350113178383, -0.05858067548906476, 8.695616991288777, 0.8911308392424653, 9.391114371637403, 8.094555884981943, -4.290838531517852, 10.79099641135041, 1.3150492298392589, 10.902284491587732, -0.8873436991601062, 2.228352198498256, 3.60927053212485, -1.1011040410767086, 10.284889522654836, 2.635879581548595, 2.535496309327691,
	}
	outliers := []float64{-12.1, -14, -30, -1000, 18.3, 19, 34, 24, 10000}

	mean_val := 3.
	std_val := 5.
	outlierRemovalTester(t, mean_val, std_val, outliers, observations)
}

func outlierRemovalTester(t *testing.T, expected_mean float64, expected_std float64, outliers []float64, observations []float64) {
	// observations taken from the normal distribution with mean 0 and std 1. Adjusted so that the sample mean and std are exactly 0 and 1 respectively.

	assert.InDelta(t, expected_mean, mean(newStatsObservations(observations)), 0.00001)
	assert.InDelta(t, expected_std, std(newStatsObservations(observations), expected_mean), 0.00001)

	everyObs := append(observations, outliers...)
	everyResults := newStatsObservations(everyObs)
	trimmed, err := outlierRemovalHelper(everyResults, expected_mean, expected_std)

	require.NoError(t, err)

	for _, out := range outliers {
		assert.False(t, contains(trimmed, out))
	}

	for _, obs := range observations {
		assert.True(t, contains(trimmed, obs))
	}

}

func contains(arr []dbmodels.StatsObservation, x float64) bool {
	for _, r := range arr {
		if r.NumericValue == x {
			return true
		}
	}
	return false
}
