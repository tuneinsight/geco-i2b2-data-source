All the operations exposed by this data source plugin to the TI Note Data Manager 
runtime are listed here, with their supported parameters, results, and output
data objects shared IDs.

# searchConcept
Exploration of the concepts of the tree-like ontology.

## Parameters
```json
{
  "path": "/TEST/test",
  "operation": "children|info",
  "limit": "200"
}
```

- `path`: path to the requested concept
- `operation`:
    - `info`: request metadata about the concept itself
    - `children`: request children of the concept (both concepts and modifiers)
- `limit`: maximum number of ontology elements returned by the search operation (optional, default to the value defined at datasource creation).
           To return all found elements, it must be set to 0.

## Results
```json
{
  "searchResult": [{
    "path": "/TEST/test",
    "appliedPath": "x",
    "name": "x",
    "displayName": "x",
    "code": "x",
    "comment": "x",
    "type": "concept|concept_container|concept_folder|modifier|modifier_container|modifier_folder|genomic_annotation",
    "leaf": true,
    "metadata": {
      "valueMetadata": {
        "creationDateTime": "x",
        "dataType": "PosInteger|Integer|Float|PosFloat|Enum|String",
        "enumValues": "x",
        "flagsToUse": "x",
        "OkToUseValues": "Y",
        "testID": "x",
        "testName": "x",
        "unitValues": [
          {
            "convertingUnits": [
              {
                "multiplyingFactor": "x",
                "units": "x"
              }
            ],
            "equalUnits": "x",
            "excludingUnits": "x",
            "normalUnits": "x"
          }
        ]
      }
    }
  }]
}
```

- `searchResult`: array of results, either concepts or modifiers
  - `path`: path to the modifier or concept
  - `appliedPath`:  path(s) onto which the modifier applies (if a modifier)
  - `name`: name of the element
  - `displayName`: nicely formatted name of the element
  - `code`: i2b2 two-elements code
  - `comment`: comment that can be used as tooltip 
  - `type`: type of the element
    - `concept`: concept
    - `concept_container`: concept with children, queryable
    - `concept_folder`: concept with children, not queryable
    - `modifier`: modifier
    - `modifier_container`: modifier with children, queryable
    - `modifier_folder`: modifier with children, not queryable
    - `genomic_annotations`: genomic annotation
  - `leaf`: true if element is a leaf, i.e. does not have children
  - `metadata`: some additional metadata (refer to the (i2b2 doc)[https://community.i2b2.org/wiki/display/DevForum/Metadata+XML+for+Medication+Modifiers] for details.)

# searchModifier
Exploration of the modifiers of the tree-like ontology.

## Parameters
```json
{
  "path": "/TEST/modifiers/",
  "appliedPath": "/test/%",
  "appliedConcept": "/TEST/test/1/",
  "operation": "concept|children|info",
  "limit": "200"
}
```

- `path`: path to the requested modifier or concept
- `appliedPath`: path(s) onto which the modifier applies
- `appliedConcept`: concept onto which the modifier applies
- `operation`:
  - `info`: request metadata about the modifier itself
  - `children`: request children of the modifier
  - `concept`: request modifiers of the requested concept
- `limit`: maximum number of ontology elements returned by the search operation (optional, default to the value defined at datasource creation).
  To return all found elements, it must be set to 0.
  
## Results
See results of `searchConcept`.

# searchOntology
Search the elements (both concepts and modifiers) of the ontology.

## Parameters
```json
{
  "searchString": "xxxx",
  "limit": "1000"
}
```

- `searchString`: string to search for in concepts and modifiers names.
- `limit`: maximum number of returned ontology elements (default 10).

## Results
See results of `searchConcept`.

# exploreQuery
Retrieve patient IDs from i2b2 based on explore query terms.
[See i2b2 CRC API for more details.](https://www.i2b2.org/software/files/PDF/current/CRC_Messaging.pdf)

## Parameters
```json
{
  "id": "99999999-9999-9999-9999-999999999999",
  "definition": {
    "selectionPanels": [{
      "not": false,
      "timing": "any|samevisit|sameinstancenum",
      "cohortItems": ["cohortName0", "cohortName1"],
      "conceptItems": [{
        "queryTerm": "/TEST/test/1/",
        "operator": "EQ|NE|GT|GE|LT||LE|BETWEEN|IN|LIKE[exact]|LIKE[begin]|LIKE[end]|LIKE[contains]",
        "value": "xxx",
        "type": "NUMBER|TEXT",
        "modifier": {
          "appliedPath": "/test/1/",
          "key": "/TEST/modifiers/1/"
        }
      }]
    }],
    "sequentialPanels": [{
    }],
    "sequentialOperators": [{
      "whichDateFirst":          "STARTDATE|ENDDATE",
      "whichObservationFirst":   "FIRST|LAST|ANY",
      "when":                    "LESS|LESSEQUAL|EQUAL",
      "whichDateSecond":         "STARTDATE|ENDDATE",
      "whichObservationSecond":  "FIRST|LAST|ANY",
      "spans": [{
        "value": 5,
        "units": "HOUR|DAY|MONTH|YEAR",
        "operator": "LESS|LESSEQUAL|EQUAL|GREATEREQUAL|GREATER"
      }]
    }],
    "timing": "any|samevisit|sameinstancenum"
  }
}
```

- `id`: ID of the query, must be an UUID
- `definition`: definition of the explore query
  - `selectionPanels`: panels of the explore query (linked together by an AND)
    - `not`: true if the panel is inverted
    - `timing`: timing of the panel
      - `any`: no constrain (default)
      - `samevisit`: constrain to the same visit
      - `sameinstancenum`: constrain to the same instance number
    - `cohortItems`: array of explore query IDs (linked together by an OR)
    - `conceptItems`: array of concepts (linked together by an OR)
      - `queryTerm`: path to the queried concept
      - `operator`: apply an operator to the queried concept 
        - `EQ`: equal (type=NUMBER)
        - `NE`: not equal (type=NUMBER)
        - `GT`: greater (type=NUMBER)
        - `GE`: greater or equal (type=NUMBER)
        - `LT`: less (type=NUMBER)
        - `LE`: less or equal (type=NUMBER)
        - `BETWEEN`: between values, value example: "100 and 200" (type=NUMBER)
        - `IN`: value among set, value example: "('NEG','NEGATIVE')" (type=TEXT)
        - `LIKE[exact]`: string is equal to (type=TEXT)
        - `LIKE[begin]`: string begins with (type=TEXT)
        - `LIKE[end]`: string ends with (type=TEXT)
        - `LIKE[contains]`: string contains (type=TEXT)
      - `value`: value to use with operator
      - `type`: type of concept
        - `NUMBER`: numeric type
        - `TEXT`: string type
      - `modifier`: apply a modifier to the queried concept
        - `AppliedPath`: path(s) onto which the modifier applies
        - `Key`: path of the modifier
  - `timing`: timing of the query
    - `any`: no constrain (default)
    - `samevisit`: constrain to the same visit
    - `sameinstancenum`: constrain to the same instance number
  - `sequentialPanels`: sequential panels of the explore query (linked together by a sequential operator, and with the `selectionPanels` by an AND)
  - `sequentialOperators`: operators determining the temporal relations between the `sequentialPanels`. The element at position `i` determines the relation between the panels at positions `i` and `i + 1`.  
    The observations identified by the first panel occur before the observations identified by the second panel if  
    the `whichDateFirst` of the `whichObservationFirst` observation in the first panel  
    occurs `when` [by `spans[0]` [and `spans[1]`]] than  
    the `whichDateSecond` of the `whichObservationSecond` observation in the second panel
    - `whichDateFirst`: the date to be considered to determine the time of the first panel
      - `STARTDATE`: the start date of the observation (default)
      - `ENDDATE`: the end date of the observation
    - `whichObservationFirst`: the observation to be considered to determine the time of the first panel
      - `FIRST`: the first observation (default)
      - `LAST`: the last observation
      - `ANY`: any observation
    - `when`: the relation between the time of the first panel and the time of the second panel
      - `LESS`: before (default)
      - `LESSEQUAL`: before or at the same time
      - `EQUAL`: at the same time
    - `whichDateSecond`: the date to be considered to determine the time of the second panel
      - `STARTDATE`: the start date of the observation (default)
      - `ENDDATE`: the end date of the observation
    - `whichObservationSecond`: the observation to be considered to determine the time of the second panel
      - `FIRST`: the first observation (default)
      - `LAST`: the last observation
      - `ANY`: any observation
    - `spans`: optionally add a time constraint to `when`, e.g. it specifies the difference between the time of the first panel and the time of the second panel (e.g. by 1 and 3 months).  
    It contains max 2 elements, the first one being the left endpoint of the time constraint, the second the right one.
      - `value`: numeric value of one of the endpoint of the time constraint
      - `units`: the units of the time constraint
        -  `HOUR`
        -  `DAY`
        -  `MONTH`
        -  `YEAR`
      - `operator`:
        -  `LESS`
        -  `LESSEQUAL`
        -  `EQUAL`
        -  `GREATEREQUAL`
        -  `GREATER`

## Output Data Objects Shared IDs
- `count`: integer containing the count of patients
- `patientList`: vector of integers containing the patient IDs

# getCohorts
Retrieve the list of saved cohorts.

## Parameters
```json
{
  "projectID": "99999999-9999-9999-9999-999999999999",
  "limit": 10
}
```

- `projectID`: ID of the project to which the cohorts to retrieve are linked
- `limit`: max number of cohorts to retrieve

## Results
```json
{
  "cohorts": [{
    "name": "Cohort 1",
    "creationDate": "xxx",
    "exploreQuery": {
      "id": "99999999-9999-9999-9999-999999999999",
      "creationDate": "xxx",
      "status": "running|success|error",
      "definition": {},
      "outputDataObjectsSharedIDs": {
        "count": "xxx",
        "patientList": "xxx"
      }
    }
  }]
}
```

- `cohorts`: array of cohorts
  - `name`: name of the cohort
  - `creationDate`: date of the creation of the cohort
  - `exploreQuery`: the query tied to the cohort
    - `id`: identifier of the query
    - `creationDate`: date of the creation of the query
    - `status`: status of the query
      - `running`: query is running
      - `success`: query successfully ran
      - `error`: query has errored
    - `definition`: definition of the query (see above for syntax)
  - `outputDataObjectsSharedIDs`:
    - `Count`: data object shared ID of the count
    - `PatientList`: data object shared ID of the patient list 

# addCohort
Add a cohort.

## Parameters
```json
{
  "name": "Cohort 1",
  "projectID": "99999999-9999-9999-9999-999999999999",
  "exploreQueryID": "99999999-9999-9999-9999-999999999999"
}
```

- `name`: name of the cohort
- `projectID`: ID of the project to which the cohort to create is linked
- `exploreQueryID`: query to associate to the cohort

# deleteCohort
Delete a cohort.

## Parameters
```json
{
  "name": "Cohort 1",
  "exploreQueryID": "99999999-9999-9999-9999-999999999999"
}
```

- `name`: name of the cohort
- `exploreQueryID`: query associated to the cohort

# survivalQuery
Run survival query.

## Parameters

```json
{
  "id": "99999999-9999-9999-9999-999999999999",
  "cohortQueryID": "xxxx",
  "startConcept": "xxxx",
  "startModifier": {
    "modifierKey": "xxxx",
    "appliedPath": "xxxx"
  },
  "startsWhen": "earliest|latest",
  "endConcept": "xxxx",
  "endModifier": {
    "modifierKey": "xxxx",
    "appliedPath": "xxxx"
  },
  "endsWhen": "earliest|latest",
  "timeGranularity": "day|week|month|year",
  "timeLimit": 10,
  "subGroupsDefinitions": [
    {
      "name": "xxxx",
      "constraint": {
        
      }
    }
  ]
}
```

- `id`: ID of the survival query, must be an UUID
- `cohortQueryID`: ID of the query which generated the cohort
- `startConcept/endConcept`: survival start/end concept
- `startModifier/endModifier`: survival start/end modifier
  - `modifierKey`: modifier key
  - `appliedPath`: modifier applied path
- `startsWhen/endsWhen`: indicates which occurrence of the start/end event to take into account (earliest|latest)
- `timeGranularity`: granularity of the bins of the survival query (day|week|month|year)
- `timeLimit`: time limit (how many bins) to consider for the survival query
- `subGroupsDefinitions`: subgroups definitions
  - `name`: name of the subgroup
  - `constraint`: `definition` as defined in exploreQuery parameters

## Output Data Objects Shared IDs
- `survivalQueryResult`: vector of integers containing the flattened event groups

Each event group is flattened as a vector of 1 + 2n elements, where n is the number of group's time points. 
The element at position 0 contains the initial count for the group, and each couple of following elements contains
the aggregated number of events of interest and the aggregated number of censoring events for each time point in the group.
All flattened event groups are concatenated in `survivalQueryResult`, whose size is then m(1 + 2n), where m is the number of event groups.

# statisticsQuery
Run statistics query.

## Parameters

```json
{
  "id": "99999999-9999-9999-9999-999999999999",
  "constraint": [
    
  ],
  "analytes": [
    
  ],
  "bucketSize": 1.5,
  "minObservations": 2
}
```

- `id`: ID of the statistics query, must be an UUID
- `constraint`: `definition` as defined in exploreQuery parameters
- `analytes`: the concepts (see `conceptItems` in "exploreQuery") used as analytes of the statistics query
- `bucketSize`: bucket size for each analyte (float64)
- `minObservations`: the total minimal number of observations for each analyte.

## Output Data Objects Shared IDs
- `statisticsQueryResult`: matrix of integers containing the number of observations for each analyte and each bucket.
Each row of the matrix represents one analyte, each column of the matrix represents a bucket. The element of the matrix
at position (i, j) contains the number of observations for the j-th bucket of the i-th analyte.