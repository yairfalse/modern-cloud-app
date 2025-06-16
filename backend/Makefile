.PHONY: build run test lint clean help

# Variables
BINARY_NAME=modernblog
MAIN_PATH=./cmd/server
BUILD_DIR=./build

## help: Display this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk '/^##/ { \
		getline target; \
		gsub(/^[^:]*:/, "", target); \
		printf "  %-15s %s\n", target, substr($$0, 4) \
	}' $(MAKEFILE_LIST)

## build: Build the application binary
build:
	@echo "Building..."
	@go build -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)
	@echo "Binary built: $(BUILD_DIR)/$(BINARY_NAME)"

## run: Run the application
run:
	@echo "Running..."
	@go run $(MAIN_PATH)

## test: Run all tests
test:
	@echo "Running tests..."
	@go test -v ./...

## lint: Run linter
lint:
	@echo "Running linter..."
	@if command -v golangci-lint &> /dev/null; then \
		golangci-lint run; \
	else \
		echo "golangci-lint not installed. Running go vet instead..."; \
		go vet ./...; \
	fi

## clean: Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@go clean

## deps: Download dependencies
deps:
	@echo "Downloading dependencies..."
	@go mod download
	@go mod tidy

## dev: Run the application with hot reload (requires air)
dev:
	@if command -v air &> /dev/null; then \
		air; \
	else \
		echo "Air not installed. Running without hot reload..."; \
		$(MAKE) run; \
	fi