package datasource

import (
	"encoding/json"
	"fmt"
	"math"
	"strings"
	"sync"

	"github.com/sirupsen/logrus"
	gecomodels "github.com/tuneinsight/sdk-datasource/pkg/models"
	gecosdk "github.com/tuneinsight/sdk-datasource/pkg/sdk"

	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/database"

	"github.com/google/uuid"
	"github.com/tuneinsight/geco-i2b2-data-source/pkg/datasource/models"
	"github.com/tuneinsight/sdk-datasource/pkg/sdk"
)

// StatisticsQueryHandler is the OperationHandler for the OperationStatisticsQuery Operation.
func (ds I2b2DataSource) StatisticsQueryHandler(
	userID string,
	jsonParameters []byte,
	outputDataObjectsSharedIDs map[gecosdk.OutputDataObjectName]gecomodels.DataObjectSharedID,
) (jsonResults []byte, outputDataObjects []gecosdk.DataObject, err error) {

	decodedParams := &models.StatisticsQueryParameters{}

	if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("decoding parameters: %v", err)
	}

	if err = json.Unmarshal(jsonParameters, decodedParams); err != nil {
		return nil, nil, fmt.Errorf("decoding parameters: %v", err)
	}
	statResults, err := ds.StatisticsQuery(userID, decodedParams)
	if err != nil {
		return nil, nil, fmt.Errorf("executing statistics query: %v", err)
	}

	for i, statResult := range statResults {

		values := [][]int64{}
		valueVector := []int64{}
		columns := []string{}

		for _, bucket := range statResult.Buckets {
			valueVector = append(valueVector, bucket.Count)
			columns = append(columns, "["+fmt.Sprintf("%f", bucket.LowerBound)+", "+fmt.Sprintf("%f", bucket.HigherBound)+"]")
		}
		values = append(values, valueVector)

		outputDataObjects = append(outputDataObjects, gecosdk.DataObject{
			//  : statResult.AnalyteName,
			OutputName: sdk.OutputDataObjectName(fmt.Sprintf("%d", i)),
			SharedID:   outputDataObjectsSharedIDs[sdk.OutputDataObjectName(fmt.Sprintf("%d", i))],
			Columns:    columns,
			IntMatrix:  values,
		})
	}
	return
}

// StatisticsQuery makes a statistics query.
func (ds I2b2DataSource) StatisticsQuery(userID string, params *models.StatisticsQueryParameters) (statResults []*models.StatsResult, err error) {

	// validating params
	err = params.Validate()
	if err != nil {
		return nil, fmt.Errorf("while validating parameters for statistics query %s: %v", params.ID, err)
	}

	logrus.Info("fetching patients for statistics query")

	// create the panel containing the analytes (OR-ed)
	analytePanel := models.Panel{
		Not:          false,
		ConceptItems: nil,
	}
	for _, analyte := range params.Analytes {
		analytePanel.ConceptItems = append(analytePanel.ConceptItems, *analyte)
	}

	_, patientCount, patientList, err := ds.ExploreQuery(userID, &models.ExploreQueryParameters{
		ID: uuid.New().String(),
		Definition: models.ExploreQueryDefinition{
			Timing:            params.Constraint.Timing,
			SelectionPanels:   append(params.Constraint.SelectionPanels, analytePanel),
			SequenceOperators: params.Constraint.SequenceOperators,
			SequentialPanels:  params.Constraint.SelectionPanels,
		},
	})

	if err != nil {
		errMsg := "when running explore query to retrieve patients for statistics query"
		logrus.Errorf("%s : %s", errMsg, err.Error())
		return nil, fmt.Errorf(errMsg)
	}

	logrus.Infof("patient count: %v", patientCount)

	if patientCount == 0 {
		// create a single empty bucket for each analyte
		for _, analyte := range params.Analytes {
			statResults = append(statResults, &models.StatsResult{
				AnalyteName: analyte.QueryTerm,
				Buckets: []*models.Bucket{
					{
						LowerBound:  0,
						HigherBound: 1,
						Count:       0,
					},
				},
			})
		}
		return
	}

	// --- get concept and modifier codes from the ontology
	conceptsInfo, modifiersInfo, err := ds.getOntologyElementsInfoForStatisticsQuery(params.Analytes)

	if err != nil {
		return nil, ds.logError("while retrieving ontology elements for statistics query: %v", err)
	}

	waitGroup := new(sync.WaitGroup)
	ontologyElementsNumber := len(conceptsInfo) + len(modifiersInfo)
	waitGroup.Add(ontologyElementsNumber)

	// the observations for each analyte are processed and sent in statsChannels
	statsChannels := make([]chan struct {
		counts      []int64
		statsResult *models.StatsResult
	}, ontologyElementsNumber)
	errChan := make(chan error)
	signal := make(chan struct{})

	// this function is an abstraction for the retrieving and processing of observations
	processMedicalConcept := func(index int, searchResultElement *models.SearchResultElement, RetrieveObservations func(string, []int64, int64) (observations []database.StatsObservation, err error)) {

		defer waitGroup.Done()

		logrus.Debugf("retrieving observations for ontology element: %s", searchResultElement.Path)
		conceptObservations, err := RetrieveObservations(searchResultElement.Code, patientList, params.MinObservations)
		if err != nil {
			errChan <- err
			return
		}
		logrus.Debugf("retrieved: %d observations for ontology element: %s", len(conceptObservations), searchResultElement.Path)

		cleanObservations, err := outlierRemoval(conceptObservations)
		if err != nil {
			errChan <- err
			return
		}
		logrus.Debugf("observations for ontology element: %s after outliers removal: %d", searchResultElement.Path, len(conceptObservations))

		counts, statsResults, err := ds.processObservations(cleanObservations, params.MinObservations, params.BucketSize)
		if err != nil {
			errChan <- err
			return
		}

		statsResults.AnalyteName = searchResultElement.Name

		statsChannels[index] <- struct {
			counts      []int64
			statsResult *models.StatsResult
		}{counts: counts, statsResult: statsResults}

	}

	for i, concept := range conceptsInfo {
		statsChannels[i] = make(chan struct {
			counts      []int64
			statsResult *models.StatsResult
		}, 1)
		go processMedicalConcept(i, concept, ds.db.RetrieveObservationsForConcept)
	}

	nbConcepts := len(conceptsInfo)
	for j, modifier := range modifiersInfo {

		index := nbConcepts + j
		statsChannels[index] = make(chan struct {
			counts      []int64
			statsResult *models.StatsResult
		}, 1)
		go processMedicalConcept(index, modifier, ds.db.RetrieveObservationsForModifier)
	}

	go func() {
		waitGroup.Wait()
		signal <- struct{}{}
	}()

	select {
	case err = <-errChan:
		return
	case <-signal:
		break
	}

	// We fetch the histogram information for each analyte within each channel that contains such information and append this information to the HTTP response.
	for _, statResultChannel := range statsChannels {
		statResult := <-statResultChannel
		statResults = append(statResults, statResult.statsResult)
	}
	return
}

func (ds I2b2DataSource) getOntologyElementsInfoForStatisticsQuery(concepts []*models.ConceptItem) (conceptsInfo []*models.SearchResultElement, modifiersInfo []*models.SearchResultElement, err error) {

	logrus.Info("get concept and modifier codes")

	modifiersNumber := 0
	for _, concept := range concepts {
		if concept.Modifier.Key == "" {
			modifiersNumber++
		}
	}

	waitGroup := &sync.WaitGroup{}
	waitGroup.Add(len(concepts) + modifiersNumber)
	logrus.Debugf("total number of ontology elements: %d", len(concepts)+modifiersNumber)
	signal := make(chan struct{})
	conceptsChannels := make([]chan *models.SearchResultElement, len(concepts))
	modifiersChannels := make([]chan *models.SearchResultElement, modifiersNumber)
	errChan := make(chan error)

	currentModifiersChannel := 0
	for i, concept := range concepts {

		conceptsChannels[i] = make(chan *models.SearchResultElement, 1)

		go func(conceptPath string, index int) {
			defer waitGroup.Done()

			//fetch the code and name of the concept
			conceptInfo, err := ds.SearchConcept(&models.SearchConceptParameters{
				Path:      conceptPath,
				Operation: models.SearchInfoOperation,
			})
			if err != nil {
				errChan <- fmt.Errorf("while retrieving code for concept %s: %v", conceptPath, err)
				return
			} else if len(conceptInfo.SearchResultElements) > 1 {
				errMsg := fmt.Sprintf("while retrieving concept code, got too many concepts for path %s:", conceptPath)
				for _, searchResultElement := range conceptInfo.SearchResultElements {
					errMsg = fmt.Sprintf("%s %s,", err, searchResultElement.Path)
				}
				errChan <- fmt.Errorf("%v", strings.TrimSuffix(errMsg, ","))
			}
			logrus.Debugf("got concept code for concept %s: %s ", conceptInfo.SearchResultElements[0].Name, conceptInfo.SearchResultElements[0].Code)
			conceptsChannels[index] <- conceptInfo.SearchResultElements[0]
		}(concept.QueryTerm, i)

		if concept.Modifier.Key == "" {

			modifiersChannels[currentModifiersChannel] = make(chan *models.SearchResultElement, 1)

			go func(modifierPath, modifierAppliedPath string, index int) {
				defer waitGroup.Done()

				//fetch the code and name of the modifier
				modifierInfo, err := ds.SearchModifier(&models.SearchModifierParameters{
					SearchConceptParameters: models.SearchConceptParameters{
						Path:      modifierPath,
						Operation: models.SearchInfoOperation,
					},
					AppliedPath:    modifierAppliedPath,
					AppliedConcept: concept.QueryTerm,
				})
				if err != nil {
					errChan <- fmt.Errorf("while retrieving code for modifier %s (applied path: %s, applied concept: %s) : %v", modifierPath, modifierAppliedPath, concept.QueryTerm, err)
					return
				} else if len(modifierInfo.SearchResultElements) > 1 {
					err := fmt.Errorf("while retrieving modifier code, got too many modifiers for path: %s, applied path: %s, applied concept: %s", modifierPath, modifierAppliedPath, concept.QueryTerm)
					for _, searchResultElement := range modifierInfo.SearchResultElements {
						err = fmt.Errorf("%s %s,", err, searchResultElement.Path)
					}
					errChan <- fmt.Errorf("%v", strings.TrimSuffix(err.Error(), ","))
				}
				logrus.Debugf("got code for modifier %s: %s ", modifierInfo.SearchResultElements[0].Name, modifierInfo.SearchResultElements[0].Code)
				modifiersChannels[index] <- modifierInfo.SearchResultElements[0]
			}(concept.Modifier.Key, concept.Modifier.AppliedPath, currentModifiersChannel)

			currentModifiersChannel++
		}
	}

	go func() {
		waitGroup.Wait()
		signal <- struct{}{}
	}()

	select {
	case err = <-errChan:
		return
	case <-signal:
		break
	}

	for _, channel := range conceptsChannels {
		conceptsInfo = append(conceptsInfo, <-channel)
	}

	for _, channel := range modifiersChannels {
		modifiersInfo = append(modifiersInfo, <-channel)
	}

	logrus.Debug("got concept and modifier codes")
	return
}

// processObservations builds a StatsResult from a set of StatsObservation.
func (ds I2b2DataSource) processObservations(statsObservations []database.StatsObservation, minObservation int64, bucketSize float64) (counts []int64, statsResult *models.StatsResult, err error) {

	if len(statsObservations) == 0 {
		logrus.Warnf("no observations present in the database for this combination of analytes and cohort definition")
		return []int64{0},
			&models.StatsResult{
				Buckets: []*models.Bucket{
					{
						LowerBound:  0,
						HigherBound: 1,
						Count:       0,
					},
				},
			}, nil
	}

	//get the minimum and maximum value of the concepts
	var maxResult = statsObservations[0]
	for _, r := range statsObservations {
		if r.NumericValue > maxResult.NumericValue {
			maxResult = r
		}
	}

	logrus.Debugf("max value :%v", maxResult.NumericValue)

	// defining the number of intervals depending on the maximum and minimum observations and the bucket size
	nbBuckets := int(math.Ceil((maxResult.NumericValue - float64(minObservation)) / bucketSize))

	logrus.Debugf("query results contains %d records", len(statsObservations))

	if len(statsObservations) < 2 {
		err = fmt.Errorf("not enough concepts to define buckets")
		return
	}

	statsResult = &models.StatsResult{
		Buckets: make([]*models.Bucket, nbBuckets),
		Unit:    statsObservations[0].Unit,
		// TODO: later on we will probably have to perform unit conversion. One possibility would be to fetch the metadataXML of a concept
		// to see what are the conversion rules for that concept. For now we make the hypothesis that everything is under the same unit
		// c.f. https://community.i2b2.org/wiki/display/DevForum/Metadata+XML+for+Medication+Modifiers
		//another option is to convert all observations for a same concept to the same unit during the ETL phase.
	}

	// from the minimum and maximum value of the selected concept we determine the boundaries of the different buckets
	current := float64(minObservation)
	logrus.Debugf("processObservations: number of interval = %d", nbBuckets)

	for i := 0; i < nbBuckets; i++ {
		statsResult.Buckets[i] = new(models.Bucket)
		interval := statsResult.Buckets[i]
		logrus.Debugf("setting interval bounds. (%v, %v) -> (%v, %v)", interval.LowerBound, interval.HigherBound, current, current+bucketSize)
		interval.LowerBound = current //TODO trim the zeroes when sending that in json format
		interval.HigherBound = current + bucketSize

		current += bucketSize
	}

	// In the following lines of code we group the query results in different buckets depending on their numerical values.
	waitGroup := &sync.WaitGroup{}
	waitGroup.Add(nbBuckets)

	channels := make([]chan struct {
		count int64
	}, nbBuckets)

	errChan := make(chan error)
	signal := make(chan struct{})

	for i, bucket := range statsResult.Buckets {
		logrus.Debugf("starting the processing of the interval with index %d", i)
		if bucket.LowerBound >= bucket.HigherBound {
			err := fmt.Errorf("the lower bound of the interval #%d is greater than the higher bound: %f >= %f", i, bucket.LowerBound, bucket.HigherBound)
			errChan <- err
			break
		}

		channels[i] = make(chan struct {
			count int64
		}, 1)

		logrus.Debugf("processObservations: assigned struct to channel with index %d", i)

		go func(i int, interval *models.Bucket) {
			defer waitGroup.Done()

			var count int64 = 0

			logrus.Debugf("about to count the number of observations that fit in interval %d", i)
			//counting the number of numerical values that belong to the [lowerbound, higherbound[ interval.
			for _, queryResult := range statsObservations {
				isLastInterval := maxResult.NumericValue == interval.HigherBound
				smallerThanHigherBound :=
					(isLastInterval && queryResult.NumericValue <= interval.HigherBound) ||
						(!isLastInterval && queryResult.NumericValue < interval.HigherBound)

				if queryResult.NumericValue >= interval.LowerBound && smallerThanHigherBound {
					count++
				}
			}

			logrus.Debugf("count for bucket [ %f , %f] is %d", interval.LowerBound, interval.HigherBound, count)
			logrus.Debugf("sending count information to channel %d", i)
			channels[i] <- struct {
				count int64
			}{count}

			logrus.Debugf("done sending count information to channel %d", i)
		}(i, bucket)

	}
	go func() {
		waitGroup.Wait()
		signal <- struct{}{}
	}()

	select {
	case err = <-errChan:
		return
	case <-signal:
		break
	}

	counts = make([]int64, 0, len(channels))
	for i, channel := range channels {
		chanResult := <-channel

		logrus.Debugf("receiving the count in the channel with index %d, %d", i, chanResult.count)
		counts = append(counts, chanResult.count)
		statsResult.Buckets[i].Count = chanResult.count
	}

	return
}

func outlierRemoval(observations []database.StatsObservation) (outputObs []database.StatsObservation, err error) {
	// implementation of the three sigma rules:  |Z| = | (x - x bar) / S | >= 3 (where S is std deviation)
	mean := mean(observations)
	std := std(observations, mean)

	return outlierRemovalHelper(observations, mean, std)
}

func outlierRemovalHelper(observations []database.StatsObservation, mean float64, std float64) (outputObs []database.StatsObservation, err error) {
	for _, o := range observations {
		Z := math.Abs((o.NumericValue - mean) / std)
		if Z <= 3 {
			outputObs = append(outputObs, o)
		}
	}
	return
}

func mean(observations []database.StatsObservation) float64 {
	var sum float64 = 0
	for _, o := range observations {
		sum += o.NumericValue
	}

	return sum / float64(len(observations))
}

func std(observations []database.StatsObservation, meanOfObs float64) float64 {
	sigmaSquared := 0.0

	for _, o := range observations {
		d := o.NumericValue - meanOfObs

		sigmaSquared += +d * d
	}

	sigmaSquared = sigmaSquared / float64(len(observations))

	return math.Sqrt(sigmaSquared)
}
