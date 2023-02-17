package models

import (
	"encoding/xml"
	"fmt"
	"math"
	"strconv"
	"sync"

	"github.com/sirupsen/logrus"
)

// --- request

// NewCrcPdoReqFromInputList returns a new request object for i2b2 pdo request.
func NewCrcPdoReqFromInputList(patientSetID string, returnPatientList, returnObservations bool) CrcPdoReqFromInputListMessageBody {

	// PDO header
	pdoHeader := PdoHeader{
		PatientSetLimit: "0",
		EstimatedTime:   "0",
		RequestType:     "getPDO_fromInputList",
	}

	// PDO request
	pdoRequest := PdoRequestFromInputList{
		Type: "crcpdons:GetPDOFromInputList_requestType",
		Xsi:  "http://www.w3.org/2001/XMLSchema-instance",
	}

	// set request for patient set ID
	pdoRequest.InputList.PatientList.Max = "1000000"
	pdoRequest.InputList.PatientList.Min = "0"
	pdoRequest.InputList.PatientList.PatientSetCollID = patientSetID
	pdoRequest.OutputOption.Name = "none"

	if returnPatientList {
		pdoRequest.OutputOption.PatientSet = &OutputOptionItem{
			Blob:     "false",
			TechData: "false",
			OnlyKeys: "true",
			Select:   "using_input_list",
		}
	}

	if returnObservations {
		pdoRequest.OutputOption.ObservationSet = &OutputOptionItem{
			Blob:     "false",
			TechData: "false",
			OnlyKeys: "false",
			Select:   "using_filter_list",
		}
	}

	return CrcPdoReqFromInputListMessageBody{
		PdoHeader:  pdoHeader,
		PdoRequest: pdoRequest,
	}
}

// CrcPdoReqFromInputListMessageBody is an i2b2 XML message body for CRC PDO request from input list.
type CrcPdoReqFromInputListMessageBody struct {
	XMLName xml.Name `xml:"message_body"`

	PdoHeader  PdoHeader               `xml:"crcpdons:pdoheader"`
	PdoRequest PdoRequestFromInputList `xml:"crcpdons:request"`
}

// PdoHeader is an i2b2 XML header for PDO requests.
type PdoHeader struct {
	PatientSetLimit string `xml:"patient_set_limit"`
	EstimatedTime   string `xml:"estimated_time"`
	RequestType     string `xml:"request_type"`
}

// OutputOptionItem is an item of OutputOption
type OutputOptionItem struct {
	Select          string `xml:"select,attr"`
	OnlyKeys        string `xml:"onlykeys,attr"`
	Blob            string `xml:"blob,attr"`
	TechData        string `xml:"techdata,attr"`
	SelectionFilter string `xml:"selection_filter,attr"`
}

// PdoRequestFromInputList is an i2b2 XML PDO request - from input list.
type PdoRequestFromInputList struct {
	Type string `xml:"xsi:type,attr"`
	Xsi  string `xml:"xmlns:xsi,attr"`

	InputList struct {
		PatientList struct {
			Max              string `xml:"max,attr"`
			Min              string `xml:"min,attr"`
			PatientSetCollID string `xml:"patient_set_coll_id"`
		} `xml:"patient_list,omitempty"`
	} `xml:"input_list"`

	FilterList struct {
		Panel []Panel `xml:"panel"`
	} `xml:"filter_list"`

	OutputOption struct {
		Name           string            `xml:"name,attr"`
		PatientSet     *OutputOptionItem `xml:"patient_set,omitempty"`
		ObservationSet *OutputOptionItem `xml:"observation_set,omitempty"`
	} `xml:"output_option"`
}

// --- response

// Observation is an i2b2 observation.
type Observation struct {
	EventID struct {
		Text   string `xml:",chardata"`
		Source string `xml:"source,attr"`
	} `xml:"event_id"`
	PatientID string `xml:"patient_id"`
	ConceptCd struct {
		Text string `xml:",chardata"`
		Name string `xml:"name,attr"`
	} `xml:"concept_cd"`
	ObserverCd struct {
		Text   string `xml:",chardata"`
		Source string `xml:"source,attr"`
	} `xml:"observer_cd"`
	StartDate  string `xml:"start_date"`
	ModifierCd struct {
		Text string `xml:",chardata"`
		Name string `xml:"name,attr"`
	} `xml:"modifier_cd"`
	InstanceNum string `xml:"instance_num"`
	ValueTypeCd string `xml:"valuetype_cd"`
	TvalChar    string `xml:"tval_char"`
	NvalNum     struct {
		Text  string `xml:",chardata"`
		Units string `xml:"units,attr"`
	} `xml:"nval_num"`
	ValueflagCD struct {
		Text string `xml:",chardata"`
		Name string `xml:"name,attr"`
	} `xml:"valueflag_cd"`
	QuantityNum string `xml:"quantity_num"`
	UnitsCd     string `xml:"units_cd"`
	EndDate     string `xml:"end_date"`
	LocationCD  struct {
		Text string `xml:",chardata"`
		Name string `xml:"name,attr"`
	} `xml:"location_cd"`
}

// ObservationSet is an i2b2 observation set.
type ObservationSet struct {
	PanelName   string        `xml:"panel_name,attr"`
	Observation []Observation `xml:"observation"`
}

func (os ObservationSet) mean() (float64, error) {
	var sum float64 = 0
	for _, o := range os.Observation {
		if nvalNum, err := strconv.ParseFloat(o.NvalNum.Text, 64); err == nil {
			sum += nvalNum
		} else {
			return -1, fmt.Errorf("while computing mean of observation set: %v", err)
		}
	}
	return sum / float64(len(os.Observation)), nil
}

func (os ObservationSet) meanAndStd() (mean, std float64, err error) {

	if len(os.Observation) == 0 {
		return 0, 0, nil
	}

	mean = 0
	for _, o := range os.Observation {
		if nvalNum, err := strconv.ParseFloat(o.NvalNum.Text, 64); err == nil {
			mean += nvalNum
		} else {
			return -1, -1, fmt.Errorf("while computing mean of observation set: %v", err)
		}
	}

	mean = mean / float64(len(os.Observation))

	sigmaSquared := 0.0
	if err != nil {
		return -1, -1, fmt.Errorf("while computing std of observation set: %v", err)
	}

	for _, o := range os.Observation {
		if nvalNum, err := strconv.ParseFloat(o.NvalNum.Text, 64); err == nil {
			d := nvalNum - mean
			sigmaSquared += +d * d
		} else {
			return -1, -1, fmt.Errorf("while computing std of observation set: %v", err)
		}
	}

	sigmaSquared = sigmaSquared / float64(len(os.Observation))

	return mean, math.Sqrt(sigmaSquared), nil

}

// RemoveOutliers remove outliers from the observation set by applying the three sigma rule
func (os *ObservationSet) RemoveOutliers() error {
	// implementation of the three sigma rules:  |Z| = | (x - x bar) / S | >= 3 (where S is std deviation) <- from CHUV
	mean, std, err := os.meanAndStd()
	if err != nil {
		return fmt.Errorf("while removing outliers from observation set: %s", os.PanelName)
	}

	cleanedObs := make([]Observation, 0)
	for _, o := range os.Observation {
		if nvalNum, err := strconv.ParseFloat(o.NvalNum.Text, 64); err == nil {
			z := math.Abs((nvalNum - mean) / std)
			if z <= 3 {
				cleanedObs = append(cleanedObs, o)
			}
		} else {
			return fmt.Errorf("while removing outliers from observation set: %s", os.PanelName)
		}
	}

	os.Observation = cleanedObs

	return nil
}

// BinObservations bins the observations of the observation set.
func (os ObservationSet) BinObservations(minValue int64, bucketSize float64) (statsResult *StatsResult, err error) {

	// ricorda di aggiungere telemetria al di fuori!!!

	if len(os.Observation) == 0 {
		logrus.Warnf("no observations present in the database for this combination of analytes and cohort definition")
		return &StatsResult{
			Buckets: []*Bucket{
				{
					LowerBound:  float64(minValue),
					HigherBound: float64(minValue) + bucketSize,
					Count:       0,
				},
			},
		}, nil
	}

	// get max observation value
	maxValue, _ := strconv.ParseFloat(os.Observation[0].NvalNum.Text, 64)
	for _, o := range os.Observation[1:] {
		nvalNum, _ := strconv.ParseFloat(o.NvalNum.Text, 64)
		if nvalNum > maxValue {
			maxValue = nvalNum
		}
	}

	logrus.Debugf("max value :%v", maxValue)

	// defining the number of buckets depending on the maximum and minimum observation values and the bucket size
	nbBuckets := int(math.Ceil((maxValue - float64(minValue)) / bucketSize))
	if nbBuckets == 0 { // needed in case maxValue == minValue
		nbBuckets = 1
	}
	logrus.Debugf("number of buckets = %d", nbBuckets)

	statsResult = &StatsResult{
		Buckets: make([]*Bucket, nbBuckets),
		Unit:    os.Observation[0].UnitsCd,
		// TODO: later on we will probably have to perform unit conversion. One possibility would be to fetch the metadataXML of a concept <- from CHUV
		// to see what are the conversion rules for that concept. For now we make the hypothesis that everything is under the same unit
		// c.f. https://community.i2b2.org/wiki/display/DevForum/Metadata+XML+for+Medication+Modifiers
		//another option is to convert all observations for a same concept to the same unit during the ETL phase.
	}

	// determine the boundaries of the different buckets
	current := float64(minValue)
	for i := 0; i < nbBuckets; i++ {
		statsResult.Buckets[i] = new(Bucket)
		interval := statsResult.Buckets[i]
		logrus.Debugf("setting interval bounds. (%v, %v) -> (%v, %v)", interval.LowerBound, interval.HigherBound, current, current+bucketSize)
		interval.LowerBound = current //TODO trim the zeroes when sending that in json format
		interval.HigherBound = current + bucketSize

		current += bucketSize
	}

	// bin the observations in the repsective buckets
	waitGroup := &sync.WaitGroup{}
	waitGroup.Add(nbBuckets)

	channels := make([]chan struct {
		count int64
	}, nbBuckets)

	errChan := make(chan error)
	signal := make(chan struct{})

	for i, bucket := range statsResult.Buckets { // <- this should be optimized, iterate only once over the observations and put them in the right bucket

		logrus.Debugf("processing interval: %d", i)

		channels[i] = make(chan struct {
			count int64
		}, 1)

		go func(i int, interval *Bucket) {
			defer waitGroup.Done()

			var count int64 = 0

			// counting the number of numerical values that belong to the [lowerbound, higherbound[ interval.
			for _, o := range os.Observation {
				nvalNum, _ := strconv.ParseFloat(o.NvalNum.Text, 64)
				isLastInterval := maxValue == interval.HigherBound
				smallerThanHigherBound :=
					(isLastInterval && nvalNum <= interval.HigherBound) ||
						(!isLastInterval && nvalNum < interval.HigherBound)

				if nvalNum >= interval.LowerBound && smallerThanHigherBound {
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

	counts := make([]int64, 0, len(channels))
	for i, channel := range channels {
		chanResult := <-channel

		logrus.Debugf("receiving the count in the channel with index %d, %d", i, chanResult.count)
		counts = append(counts, chanResult.count)
		statsResult.Buckets[i].Count = chanResult.count
	}

	return

}

// Bucket represents a bucket.
// The lower bound is inclusive, the higher bound is exclusive: [lower bound, higher bound[
type Bucket struct {
	LowerBound  float64
	HigherBound float64
	Count       int64 // contains the count of subjects in this bucket
}

// StatsResult contains the information to build the histogram of observations for an analyte.
type StatsResult struct {
	Buckets []*Bucket
	Unit    string
	//concept or modifier name
	AnalyteName string
}

// CrcPdoRespMessageBody is an i2b2 XML message body for CRC PDO response.
type CrcPdoRespMessageBody struct {
	XMLName xml.Name `xml:"message_body"`

	Response struct {
		Xsi         string `xml:"xsi,attr"`
		Type        string `xml:"type,attr"`
		PatientData struct {
			PatientSet struct {
				Patient []struct {
					PatientID string `xml:"patient_id"`
					Param     []struct {
						Text             string `xml:",chardata"`
						Type             string `xml:"type,attr"`
						ColumnDescriptor string `xml:"column_descriptor,attr"`
						Column           string `xml:"column,attr"`
					} `xml:"param"`
				} `xml:"patient"`
			} `xml:"patient_set,omitempty"`
			ObservationSet []ObservationSet `xml:"observation_set,omitempty"`
		} `xml:"patient_data"`
	} `xml:"response"`
}
