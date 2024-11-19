NAME=bruin
BUILD_DIR ?= bin
BUILD_SRC=.

NO_COLOR=\033[0m
OK_COLOR=\033[32;01m
ERROR_COLOR=\033[31;01m
WARN_COLOR=\033[33;01m

.PHONY: all clean test build tools format pre-commit tools-update
all: clean deps test build

deps: tools
	@printf "$(OK_COLOR)==> Installing dependencies$(NO_COLOR)\n"
	@go mod tidy

build: deps
	@echo "$(OK_COLOR)==> Building the application...$(NO_COLOR)"
	@CGO_ENABLED=1 go build -v -tags="no_duckdb_arrow" -ldflags="-s -w -X main.Version=$(or $(tag), dev-$(shell git describe --tags --abbrev=0))" -o "$(BUILD_DIR)/$(NAME)" "$(BUILD_SRC)"


integration-test: build
	@rm -rf integration-tests
	@echo "$(OK_COLOR)==> Running integration tests...$(NO_COLOR)"
	@TELEMETRY_OPTOUT=1 ./bin/bruin init integration-tests integration-tests
	@cd integration-tests && git init
	@TELEMETRY_OPTOUT=1 ./bin/bruin run --use-uv integration-tests
	@TELEMETRY_OPTOUT=1 ./bin/bruin validate integration-tests
    @TELEMETRY_OPTOUT=1 ./bin/bruin internal parse-pipeline integration-tests | diff integration-tests/parsed_pipeline.json -
    @TELEMETRY_OPTOUT=1 ./bin/bruin internal parse-asset integration-tests/assets/asset.py  | diff integration-tests/parsed_asset_py.json -
    @TELEMETRY_OPTOUT=1 ./bin/bruin internal parse-asset integration-tests/assets/chess_games.asset.yml  | diff integration-tests/parsed_chess_games.json -
    @TELEMETRY_OPTOUT=1 ./bin/bruin internal parse-asset integration-tests/assets/chess_profiles.asset.yml  | diff integration-tests/parsed_chess_profiles.json -
    @TELEMETRY_OPTOUT=1 ./bin/bruin internal parse-asset integration-tests/assets/asset.py  | diff integration-tests/parsed_summary.json -


clean:
	@rm -rf ./bin

test: test-unit

test-unit:
	@echo "$(OK_COLOR)==> Running the unit tests$(NO_COLOR)"
	@go test -race -cover -timeout 60s ./...

format: tools
	@echo "$(OK_COLOR)>> [go vet] running$(NO_COLOR)" & \
	go vet ./... &

	@echo "$(OK_COLOR)>> [gci] running$(NO_COLOR)" & \
	gci write cmd pkg main.go &

	@echo "$(OK_COLOR)>> [gofumpt] running$(NO_COLOR)" & \
	gofumpt -w cmd pkg &

	@echo "$(OK_COLOR)>> [golangci-lint] running$(NO_COLOR)" & \
	golangci-lint run --timeout 10m60s ./...  & \
	wait

tools:
	@if ! command -v gci > /dev/null ; then \
		echo ">> [$@]: gci not found: installing"; \
		go install github.com/daixiang0/gci@latest; \
	fi

	@if ! command -v gofumpt > /dev/null ; then \
		echo ">> [$@]: gofumpt not found: installing"; \
		go install mvdan.cc/gofumpt@latest; \
	fi

	@if ! command -v golangci-lint > /dev/null ; then \
		echo ">> [$@]: golangci-lint not found: installing"; \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest; \
	fi

tools-update:
	go install github.com/daixiang0/gci@latest; \
	go install mvdan.cc/gofumpt@latest; \
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest;
