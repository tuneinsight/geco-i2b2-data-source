module github.com/ldsec/geco-i2b2-data-source

go 1.17

replace github.com/ldsec/geco => ./third_party/geco

require (
	github.com/ldsec/geco v0.0.2-0.20211215101444-5aa7d423be0d
	github.com/lib/pq v1.9.0
	github.com/sirupsen/logrus v1.8.1
	github.com/stretchr/testify v1.7.0
)

require (
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	golang.org/x/sys v0.0.0-20211015200801-69063c4bb744 // indirect
	gopkg.in/yaml.v3 v3.0.0-20210107192922-496545a6307b // indirect
)
