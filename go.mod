module github.com/tuneinsight/geco-i2b2-data-source

go 1.15

//replace github.com/tuneinsight/sdk-datasource => ../sdk-datasource

require (
	github.com/lib/pq v1.10.4
	github.com/sirupsen/logrus v1.8.1
	github.com/stretchr/testify v1.7.0
	github.com/tuneinsight/sdk-datasource v0.0.0-20220131221450-d3aa80f5dd77
)
