All the operations exposed by this data source plugin to the GeCo Data Manager 
runtime are listed here, with their supported parameters, results, and output
data objects shared IDs.

# searchConcept
Exploration of the concepts of the tree-like ontology.

## Parameters
```json
{
  "Path": "/TEST/test",
  "Operation": "children|info"
}
```

- `Path`: path to the requested concept
- `Operation`:
    - `info`: request metadata about the concept itself
    - `children`: request children of the concept

## Results
```json
{
  "SearchResults": [{
    "Path": "/TEST/test",
    "AppliedPath": "x",
    "Name": "x",
    "DisplayName": "x",
    "Code": "x",
    "Comment": "x",
    "Type": "concept|concept_container|concept_folder|modifier|modifier_container|modifier_folder|genomic_annotation",
    "Leaf": true,
    "Metadata": {
      "DataType": "PosInteger|Integer|Float|PosFloat|Enum|String",
      "OkToUseValues": "Y",
      "UnitValues": {
        "NormalUnits": "x"
      }
    }
  }]
}
```

- `SearchResults`: array of results, either concepts or modifiers
  - `Path`: path to the modifier or concept
  - `AppliedPath`:  path(s) onto which the modifier applies (if a modifier)
  - `Name`: name of the element
  - `DisplayName`: nicely formatted name of the element
  - `Code`: i2b2 two-elements code
  - `Comment`: comment that can be used as tooltip 
  - `Type`: type of the element
    - `concept`: concept
    - `concept_container`: concept with children, queryable
    - `concept_folder`: concept with children, not queryable
    - `modifier`: modifier
    - `modifier_container`: modifier with children, queryable
    - `modifier_folder`: modifier with children, not queryable
    - `genomic_annotations`: genomic annotation
  - `Leaf`: true if element is a leaf, i.e. does not have children
  - `Metadata`: some additional metadata
    - `DataType`: detailed type of data
      - `PosInteger`: positive integers
      - `Integer`: integers
      - `PosFloat`: positive floats
      - `Float`: floats
      - `Enum`: enumerated values (string)
      - `String`: free text (string)
    - `OkToUseValues`: is a "Y" if can use values, a message saying why otherwise
    - `UnitValues`: metadata about unit of the value
      - `NormalUnits`: specify the unit of the value

# searchModifier
Exploration of the modifiers of the tree-like ontology.

## Parameters
```json
{
  "Path": "/TEST/modifiers/",
  "AppliedPath": "/test/%",
  "AppliedConcept": "/TEST/test/1/",
  "Operation": "concept|children|info"
}
```

- `Path`: path to the requested modifier or concept
- `AppliedPath`: path(s) onto which the modifier applies
- `AppliedConcept`: concept onto which the modifier applies
- `Operation`:
  - `info`: request metadata about the modifier itself
  - `children`: request children of the modifier
  - `concept`: request modifiers of the requested concept
  
## Results
See results of `searchConcept`.

# exploreQuery
Retrieve patient IDs from i2b2 based on explore query terms.
[See i2b2 CRC API for more details.](https://www.i2b2.org/software/files/PDF/current/CRC_Messaging.pdf)

## Parameters
```json
{
  "ID": "99999999-9999-9999-9999-999999999999",
  "Definition": {
    "Panels": [{
      "Not": false,
      "Timing": "any|samevisit|sameinstancenum",
      "CohortItems": ["cohortName0", "cohortName1"],
      "ConceptItems": [{
        "QueryTerm": "/TEST/test/1/",
        "Operator": "EQ|NE|GT|GE|LT||LE|BETWEEN|IN|LIKE[exact]|LIKE[begin]|LIKE[end]|LIKE[contains]",
        "Value": "xxx",
        "Type": "NUMBER|TEXT",
        "Modifier": {
          "AppliedPath": "/test/1/",
          "Key": "/TEST/modifiers/1/"
        }
      }]
    }],
    "Timing": "any|samevisit|sameinstancenum"
  }
}
```

- `ID`: ID of the query, must be an UUID
- `Definition`: definition of the explore query
  - `Panels`: panels of the explore query (linked together by an AND)
    - `Not`: true if the panel is inverted
    - `Timing`: timing of the panel
      - `any`: no constrain (default)
      - `samevisit`: constrain to the same visit
      - `sameinstancenum`: constrain to the same instance number
    - `CohortItems`: array of cohort names if querying for cohorts (linked together by an OR)
    - `ConceptItems`: array of concepts if querying for concepts (linked together by an OR)
      - `QueryTerm`: path to the queried concept
      - `Operator`: apply an operator to the queried concept 
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
      - `Value`: value to use with operator
      - `Type`: type of concept
        - `NUMBER`: numeric type
        - `TEXT`: string type
      - `Modifier`: apply a modifier to the queried concept
        - `AppliedPath`: path(s) onto which the modifier applies
        - `Key`: path of the modifier
  - `Timing`: timing of the query
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
  "Limit": 10
}
```

- `Limit`: max number of cohorts to retrieve

## Results
```json
{
  "Cohorts": [{
    "Name": "Cohort 1",
    "CreationDate": "xxx",
    "ExploreQuery": {
      "ID": "99999999-9999-9999-9999-999999999999",
      "CreationDate": "xxx",
      "Status": "running|success|error",
      "Definition": {},
      "OutputDataObjectsSharedIDs": {
        "Count": "xxx",
        "PatientList": "xxx"
      }
    }
  }]
}
```

- `Cohorts`: array of cohorts
  - `Name`: name of the cohort
  - `CreationDate`: date of the creation of the cohort
  - `ExploreQuery`: the query tied to the cohort
    - `ID`: identifier of the query
    - `CreationDate`: date of the creation of the query
    - `Status`: status of the query
      - `running`: query is running
      - `success`: query successfully ran
      - `error`: query has errored
    - `Definition`: definition of the query (see above for syntax)
  - `OutputDataObjectsSharedIDs`:
    - `Count`: data object shared ID of the count
    - `PatientList`: data object shared ID of the patient list 

# addCohort
Add a cohort.

## Parameters
```json
{
  "Name": "Cohort 1",
  "ExploreQueryID": "99999999-9999-9999-9999-999999999999"
}
```

- `Name`: name of the cohort
- `ExploreQueryID`: query to associate to the cohort

# deleteCohort
Delete a cohort.

## Parameters
```json
{
"Name": "Cohort 1",
"ExploreQueryID": "99999999-9999-9999-9999-999999999999"
}
```

- `Name`: name of the cohort
- `ExploreQueryID`: query associated to the cohort
