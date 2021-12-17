package i2b2datasource

// Operation is an operation of the data source supported by I2b2DataSource.Query.
type Operation string

// Enumerated values for Operation.
const (
	OperationSearchConcept  Operation = "searchConcept"
	OperationSearchModifier Operation = "searchModifier"
	OperationExploreQuery   Operation = "exploreQuery"
	OperationGetCohorts     Operation = "getCohorts"
	OperationAddCohort      Operation = "addCohort"
	OperationDeleteCohort   Operation = "deleteCohort"
	OperationSurvivalQuery  Operation = "survivalQuery"
	OperationSearchOntology Operation = "searchOntology"
)
