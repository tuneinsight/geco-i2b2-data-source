All the operations exposed by this data source plugin to the GeCo Data Manager 
runtime are listed here, with their supported parameters, results, and output
data objects shared IDs.

# searchConcept
Exploration of the concepts of the tree-like ontology.

## Parameters
```json
{
  "path": "/TEST/test",
  "operation": "children|info"
}
```

- `path`: path to the requested concept
- `operation`:
    - `info`: request metadata about the concept itself
    - `children`: request children of the concept (both concepts and modifiers)

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
  "operation": "concept|children|info"
}
```

- `path`: path to the requested modifier or concept
- `appliedPath`: path(s) onto which the modifier applies
- `appliedConcept`: concept onto which the modifier applies
- `operation`:
  - `info`: request metadata about the modifier itself
  - `children`: request children of the modifier
  - `concept`: request modifiers of the requested concept
  
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
    "panels": [{
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
    "timing": "any|samevisit|sameinstancenum"
  }
}
```

- `id`: ID of the query, must be an UUID
- `definition`: definition of the explore query
  - `panels`: panels of the explore query (linked together by an AND)
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

## Output Data Objects Shared IDs
- `count`: integer containing the count of patients
- `patientList`: vector of integers containing the patient IDs

# getCohorts
Retrieve the list of saved cohorts.

## Parameters
```json
{
  "limit": 10
}
```

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
  "exploreQueryID": "99999999-9999-9999-9999-999999999999"
}
```

- `name`: name of the cohort
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
Perform survival query.

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
  "timeLimit": "10",
  "subGroupsDefinitions": [
    {
      "name": "xxxx",
      "timing": "any|samevisit|sameinstance",
      "panels": [
        {
          
        }
      ]
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
  - `timing`: timing of the subgroup
  - `panels`: panels defining the subgroup, as defined in exploreQuery

## Output Data Objects Shared IDs
- `survivalQueryResult`: vector of integers containing the flattened event groups

Each event group is flattened as a vector of 1 + 2n elements, where n is the number of group's time points. 
The element at position 0 contains the initial count for the group, and each couple of following elements contains
the aggregated number of events of interest and the aggregated number of censoring events for each time point in the group.
All flattened event groups are concatenated in `survivalQueryResult`, whose size is then m(1 + 2n), where m is the number of event groups.
