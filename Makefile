export DATASOURCE_VERSION := $(shell scripts/version.sh)
export USER_GROUP := $(shell id -u):$(shell id -g)
export I2B2_DOCKER_IMAGE ?= ghcr.io/tuneinsight/i2b2-geco:$(DATASOURCE_VERSION)
export COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1
export GIT_LFS_SKIP_SMUDGE=1

.PHONY: test clean
test: go-imports go-lint go-unit-tests i2b2-test
clean:
	rm -f ./build/geco-i2b2-data-source.so

# --- i2b2 docker
.PHONY: i2b2-docker-compose i2b2-test
i2b2-docker-compose: # use ARGS to pass to docker-compose arguments, e.g. make i2b2-docker-compose ARGS="up -d"
	cd deployments && docker-compose -f i2b2.yml $(ARGS)
i2b2-test:
	cd test/i2b2 && ./test_i2b2_docker.sh

# --- go sources
.PHONY:	go-build-plugin go-build-prod-plugin go-build-plugin-docker go-imports go-lint go-unit-tests
go-build-plugin: export CGO_ENABLED=1
go-build-plugin: export GOOS=linux
go-build-plugin:
	go build -buildmode=plugin -v -o ./build/ ./cmd/...

go-build-prod-plugin: export CGO_ENABLED=1
go-build-prod-plugin: export GOOS=linux
go-build-prod-plugin:
	go build -buildmode=plugin -trimpath -ldflags "-s -w" -v -o ./build/ ./cmd/...

#to be tested
go-build-plugin-docker: export CGO_ENABLED=1
go-build-plugin-docker: export GOOS=linux
go-build-plugin-docker:
	docker run --rm -v "$(PWD)":/usr/src/geco-i2b2-data-source -w /usr/src/geco-i2b2-data-source golang:1.17-alpine /bin/sh -c "apk add --no-cache git make build-base gcompat && go build -buildmode=plugin -v -o ./build/ ./cmd/..."

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
