# GeCo i2b2 Data Source Plugin

## GeCo Data Source Plugin API Operations
[The operations are documented here.](API.md)

## Build
Retrieve git submodule of GeCo:
```shell
git submodule update --init --recursive
```

Generate GeCo Swagger files:
```shell
make geco-swagger-gen
```

Build plugin to `build/geco-i2b2-data-source.so`:
```shell
make go-build-plugin
```

## Test
### Start dependencies
Start GeCo (only the database for the moment):
```shell
make geco-docker-compose ARGS="up -d postgresql"
```

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
  - `datasource/`: definition of the i2b2 GeCo data source
    - `database/`: database wrapper for the datasource
- `scripts/`: utility scripts
- `test/i2b2/`: test files for the i2b2 docker image
- `third_party/geco/`: git submodule for the GeCo source code

### Useful commands
Start psql in the running postgresql container:
```shell
make geco-docker-compose ARGS="exec postgresql psql -U postgres"
```

### About the GeCo dependency
- GeCo is included in the repository as a submodule (in `third_party/geco`) and the `go.mod` file includes a `replace` directive in order to use it.
- This is notably due to the use of the development deployment of GeCo to be used for the testing of this plugin.
- Ultimately, some definitions from this plugin (e.g. DataSource interface) and from GeCo (e.g. dev deployment) need to be extracted to a public repository to serve as an SDK for data source plugins.
