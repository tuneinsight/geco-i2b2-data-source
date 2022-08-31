# TI Note i2b2 Data Source Plugin

## TI Note i2b2 Data Source Plugin API Operations
[The operations are documented here.](API.md)

## Build
Build plugin to `build/geco-i2b2-data-source.so`:
```shell
make go-build-plugin
```

## Test

### Start dependencies

Start i2b2:
```shell
make i2b2-docker-compose ARGS="up -d"
```

### Run tests
Test i2b2 docker:
```shell
make i2b2-test
```

Run go unit tests i2b2 docker:
```shell
make go-unit-tests
```

## Development
### Source code organization
- `build/package/i2b2/`: i2b2 docker image definition
- `cmd/geco-i2b2-data-source/`: go main package for the plugin
- `pkg/`: exported go code
  - `i2b2client/`: client for i2b2 HTTP XML API
  - `datasource/`: definition of the i2b2 data source
    - `database/`: database wrapper for the datasource
- `scripts/`: utility scripts
- `test/i2b2/`: test files for the i2b2 docker image
