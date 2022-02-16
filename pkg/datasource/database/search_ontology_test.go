package database

import (
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
)

func TestSearchOntology(t *testing.T) {

	t.Run("Search \"fier\"", func(t *testing.T) {
		db := getDB(t)
		defer dbCleanUp(t, db)
		ontologyElements, err := db.SearchOntology("fier", "10")
		assert.NoError(t, err)
		logrus.Debug(ontologyElements)
	})

	t.Run("Search \"2\"", func(t *testing.T) {
		db := getDB(t)
		defer dbCleanUp(t, db)
		ontologyElements, err := db.SearchOntology("3", "10")
		assert.NoError(t, err)
		logrus.Debug(ontologyElements)
	})

	t.Run("Search \"text\"", func(t *testing.T) {
		db := getDB(t)
		defer dbCleanUp(t, db)
		ontologyElements, err := db.SearchOntology("text", "10")
		assert.NoError(t, err)
		logrus.Debug(ontologyElements)
	})

}
