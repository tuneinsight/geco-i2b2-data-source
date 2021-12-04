#VERSION := $(shell scripts/version.sh)
USER_GROUP := $(shell id -u):$(shell id -g)
DOCKER_IMAGE ?= ghcr.io/ldsec/geco-i2b2-data-source:$(VERSION)

export COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1

# todo: set up CI with DB from geco for later , ensure exec times are OK
# todo: assumes geco submodule has been retrioeved:
# todo: gha caching https://evilmartians.com/chronicles/build-images-on-github-actions-with-docker-layer-caching
# -> connect as postgres in geco DB like this
# docker exec -it i2b2postgresql psql -U postgres
# CREATE ROLE i2b2 LOGIN PASSWORD 'i2b2';
# ALTER USER i2b2 CREATEDB;

# todo: make clean swagger-gen
# todo pushd third_party/geco && make clean swagger-gen && popd

start-geco-dev-local-3nodes:
	make -C third_party/geco/deployments/dev-local-3nodes docker-compose ARGS="up -d postgresql"
	# todo: only the DB at the moment

# use ARGS to pass to docker-compose arguments, e.g. make docker-compose ARGS="up -d"
i2b2-docker-compose:
	cd test/i2b2 && docker-compose -f docker-compose.yml $(ARGS)
	# todo: version etc. to pass

test-i2b2:
	cd test/i2b2 && ./test_i2b2_docker.sh

# --- go source code
.PHONY: build-bin test-go test clean
build-plugin:
	go build -buildmode=plugin -v -o ./build/ ./cmd/...
test-go: go-imports go-lint go-unit-tests
clean: go-swagger-clean
	rm -f ./build/geco-cli ./build/geco-server

.PHONY:	go-imports go-lint go-unit-tests
go-imports:
	@echo Checking correct formatting of files
	@{ \
  		GO111MODULE=off go get -u golang.org/x/tools/cmd/goimports; \
		files=$$( goimports -w -l . ); \
		if [ -n "$$files" ]; then \
		echo "Files not properly formatted: $$files"; \
		exit 1; \
		fi; \
		if ! go vet ./...; then \
		exit 1; \
		fi \
	}

go-lint:
	@echo Checking linting of files
	@{ \
		GO111MODULE=off go get -u golang.org/x/lint/golint; \
		el="_test.go"; \
		lintfiles=$$( golint ./... | egrep -v "$$el" ); \
		if [ -n "$$lintfiles" ]; then \
		echo "Lint errors:"; \
		echo "$$lintfiles"; \
		exit 1; \
		fi \
	}

go-unit-tests:
	go test -v -short -p=1 ./...
