package database

import (
	"fmt"
	"strconv"
)

// SearchOntology retrieves the elements (both concepts and modifiers, at most @limit, default 10) of the ontology whose names contains @searchString.
func (db PostgresDatabase) SearchOntology(searchString, limit string) (ontologyElements []OntologyElement, err error) {

	limitInt, err := strconv.ParseInt(limit, 10, 64)
	if limitInt <= 0 || err != nil {
		limitInt = 10
	}

	row, err := db.handle.Query("SELECT * FROM i2b2metadata.get_ontology_elements($1,$2) ORDER BY id, fullpath DESC", searchString, limitInt)
	if err != nil {
		return nil, fmt.Errorf("while calling i2b2 database for retrieving ontology elements: %v", err)
	}
	defer row.Close()

	for row.Next() {
		var ontologyElement OntologyElement
		var fullPath string

		err = row.Scan(&ontologyElement.FullName,
			&ontologyElement.Name,
			&ontologyElement.VisualAttributes,
			&ontologyElement.BaseCode,
			&ontologyElement.MetaDataXML,
			&ontologyElement.Comment,
			&ontologyElement.AppliedPath,
			&ontologyElement.ID,
			&fullPath)
		if err != nil {
			return nil, fmt.Errorf("while reading database record stream for retrieving ontology elements: %v", err)
		}
		ontologyElements = append(ontologyElements, ontologyElement)
	}

	return
}
