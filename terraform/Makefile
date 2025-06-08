# Makefile for ModernBlog Development Environment

.PHONY: help setup dev test build deploy clean

# Colors
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[1;33m
BLUE   := \033[0;34m
NC     := \033[0m

# Configuration
PROJECT_NAME := modernblog
CLUSTER_NAME := modernblog-dev
NAMESPACE := modernblog-dev

# Help target
help:
	@echo "$(BLUE)ModernBlog Development Environment$(NC)"
	@echo ""
	@echo "$(YELLOW)Setup Commands:$(NC)"
	@echo "  setup        - Complete 5-minute development environment setup"
	@echo "  setup-verify - Validate development environment"
	@echo ""
	@echo "$(YELLOW)Development Commands:$(NC)"
	@echo "  dev          - Start development environment"
	@echo "  dev-stop     - Stop development environment"
	@echo "  dev-restart  - Restart development environment"
	@echo "  dev-logs     - View development logs"
	@echo ""
	@echo "$(YELLOW)Code Quality:$(NC)"
	@echo "  test         - Run all tests"
	@echo "  test-unit    - Run unit tests"
	@echo "  test-integration - Run integration tests"
	@echo "  lint         - Run all linters"
	@echo "  lint-go      - Lint Go code"
	@echo "  lint-tf      - Lint Terraform code"
	@echo "  fmt          - Format all code"
	@echo ""
	@echo "$(YELLOW)Build & Deploy:$(NC)"
	@echo "  build        - Build application"
	@echo "  build-api    - Build API server"
	@echo "  build-web    - Build web frontend"
	@echo "  deploy-dev   - Deploy to development"
	@echo "  deploy-staging - Deploy to staging"
	@echo ""
	@echo "$(YELLOW)Infrastructure:$(NC)"
	@echo "  infra-init   - Initialize Terraform"
	@echo "  infra-plan   - Plan infrastructure changes"
	@echo "  infra-apply  - Apply infrastructure changes"
	@echo "  infra-destroy - Destroy infrastructure"
	@echo ""
	@echo "$(YELLOW)Utilities:$(NC)"
	@echo "  clean        - Clean build artifacts and caches"
	@echo "  clean-docker - Clean Docker images and containers"
	@echo "  clean-k8s    - Clean Kubernetes resources"
	@echo "  shell-api    - Shell into API pod"
	@echo "  shell-db     - Shell into database"
	@echo ""
	@echo "$(YELLOW)AI Development:$(NC)"
	@echo "  ai-setup     - Setup Claude Code authentication"
	@echo "  ai-help      - Get AI assistance"

# =============================================================================
# Setup Commands
# =============================================================================

setup:
	@echo "$(BLUE)🚀 Starting ModernBlog development environment setup...$(NC)"
	@chmod +x setup.sh
	@./setup.sh

setup-verify:
	@echo "$(BLUE)🔍 Validating development environment...$(NC)"
	@chmod +x scripts/validate-setup.sh
	@./scripts/validate-setup.sh

# =============================================================================
# Development Commands
# =============================================================================

dev:
	@echo "$(BLUE)🚀 Starting development environment...$(NC)"
	@kubectl config use-context kind-$(CLUSTER_NAME) || (echo "$(RED)Cluster not found. Run 'make setup' first$(NC)" && exit 1)
	@docker-compose -f dev/docker-compose.dev.yml up -d
	@skaffold dev --port-forward

dev-stop:
	@echo "$(YELLOW)⏹️  Stopping development environment...$(NC)"
	@skaffold delete || true
	@docker-compose -f dev/docker-compose.dev.yml down

dev-restart: dev-stop dev

dev-logs:
	@echo "$(BLUE)📄 Viewing development logs...$(NC)"
	@kubectl logs -f deployment/$(PROJECT_NAME)-api -n $(NAMESPACE)

# =============================================================================
# Testing
# =============================================================================

test: test-unit test-integration

test-unit:
	@echo "$(BLUE)🧪 Running unit tests...$(NC)"
	@go test -v -race -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html

test-integration:
	@echo "$(BLUE)🧪 Running integration tests...$(NC)"
	@go test -v -tags=integration ./tests/integration/...

test-e2e:
	@echo "$(BLUE)🧪 Running end-to-end tests...$(NC)"
	@npm run test:e2e --prefix web

# =============================================================================
# Code Quality
# =============================================================================

lint: lint-go lint-tf lint-yaml lint-docker

lint-go:
	@echo "$(BLUE)🔍 Linting Go code...$(NC)"
	@golangci-lint run

lint-tf:
	@echo "$(BLUE)🔍 Linting Terraform code...$(NC)"
	@tflint --init
	@tflint

lint-yaml:
	@echo "$(BLUE)🔍 Linting YAML files...$(NC)"
	@yamllint . || echo "$(YELLOW)yamllint not installed, skipping...$(NC)"

lint-docker:
	@echo "$(BLUE)🔍 Linting Dockerfiles...$(NC)"
	@hadolint Dockerfile* || echo "$(YELLOW)hadolint not installed, skipping...$(NC)"

fmt: fmt-go fmt-tf

fmt-go:
	@echo "$(BLUE)📝 Formatting Go code...$(NC)"
	@go fmt ./...
	@goimports -w .

fmt-tf:
	@echo "$(BLUE)📝 Formatting Terraform code...$(NC)"
	@terraform fmt -recursive .

# =============================================================================
# Build Commands
# =============================================================================

build: build-api build-web

build-api:
	@echo "$(BLUE)🔨 Building API server...$(NC)"
	@go build -o bin/api ./cmd/api

build-web:
	@echo "$(BLUE)🔨 Building web frontend...$(NC)"
	@npm run build --prefix web

build-docker:
	@echo "$(BLUE)🐳 Building Docker images...$(NC)"
	@docker build -t $(PROJECT_NAME)-api:latest -f Dockerfile.api .
	@docker build -t $(PROJECT_NAME)-web:latest -f Dockerfile.web ./web

# =============================================================================
# Deployment
# =============================================================================

deploy-dev:
	@echo "$(BLUE)🚀 Deploying to development...$(NC)"
	@kubectl config use-context kind-$(CLUSTER_NAME)
	@skaffold run

deploy-staging:
	@echo "$(BLUE)🚀 Deploying to staging...$(NC)"
	@kubectl config use-context staging-cluster
	@skaffold run -p staging

# =============================================================================
# Infrastructure Commands (Original Terraform commands)
# =============================================================================

ENV ?= dev
TF = terraform

infra-init:
	@echo "$(BLUE)🏗️  Initializing Terraform for $(ENV) environment...$(NC)"
	@cd environments/$(ENV) && \
		$(TF) init -backend-config=backend-$(ENV).hcl -upgrade

infra-plan:
	@echo "$(BLUE)📋 Creating execution plan for $(ENV) environment...$(NC)"
	@cd environments/$(ENV) && \
		$(TF) plan -out=plan.out

infra-apply:
	@echo "$(BLUE)🚀 Applying changes to $(ENV) environment...$(NC)"
	@cd environments/$(ENV) && \
		$(TF) apply plan.out

infra-destroy:
	@echo "$(RED)⚠️  WARNING: This will destroy all resources in $(ENV) environment!$(NC)"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read confirm
	@cd environments/$(ENV) && \
		$(TF) destroy

# =============================================================================
# Utility Commands
# =============================================================================

clean: clean-go clean-docker clean-terraform

clean-go:
	@echo "$(BLUE)🧹 Cleaning Go artifacts...$(NC)"
	@go clean -cache
	@rm -rf bin/
	@rm -f coverage.out coverage.html

clean-docker:
	@echo "$(BLUE)🧹 Cleaning Docker artifacts...$(NC)"
	@docker system prune -f
	@docker images $(PROJECT_NAME)* -q | xargs docker rmi -f || true

clean-k8s:
	@echo "$(BLUE)🧹 Cleaning Kubernetes resources...$(NC)"
	@kubectl delete all --all -n $(NAMESPACE) || true

clean-terraform:
	@echo "$(BLUE)🧹 Cleaning Terraform artifacts...$(NC)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfstate*" -exec rm -f {} + 2>/dev/null || true
	@find . -type f -name "*.tfplan" -exec rm -f {} + 2>/dev/null || true
	@find . -type f -name "plan.out" -exec rm -f {} + 2>/dev/null || true

shell-api:
	@echo "$(BLUE)💻 Opening shell in API pod...$(NC)"
	@kubectl exec -it deployment/$(PROJECT_NAME)-api -n $(NAMESPACE) -- /bin/sh

shell-db:
	@echo "$(BLUE)💻 Opening database shell...$(NC)"
	@kubectl exec -it deployment/postgres -n $(NAMESPACE) -- psql -U modernblog modernblog_dev

# =============================================================================
# AI Development
# =============================================================================

ai-setup:
	@echo "$(BLUE)🤖 Setting up Claude Code authentication...$(NC)"
	@claude-code auth login

ai-help:
	@echo "$(BLUE)🤖 Opening Claude Code chat...$(NC)"
	@claude-code chat

# Initialize Terraform
init:
	@echo "Initializing Terraform for $(ENV) environment..."
	@cd environments/$(ENV) && \
		$(TF) init -backend-config=backend-$(ENV).hcl -upgrade

# Create execution plan
plan:
	@echo "Creating execution plan for $(ENV) environment..."
	@cd environments/$(ENV) && \
		$(TF) plan -out=plan.out

# Apply changes
apply:
	@echo "Applying changes to $(ENV) environment..."
	@cd environments/$(ENV) && \
		$(TF) apply plan.out

# Apply without plan file (with auto-approve for CI/CD)
apply-auto:
	@echo "Applying changes to $(ENV) environment (auto-approve)..."
	@cd environments/$(ENV) && \
		$(TF) apply -auto-approve

# Destroy infrastructure
destroy:
	@echo "WARNING: This will destroy all resources in $(ENV) environment!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read confirm
	@cd environments/$(ENV) && \
		$(TF) destroy

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	@$(TF) fmt -recursive .

# Validate configuration
validate:
	@echo "Validating Terraform configuration..."
	@$(TF) validate
	@for env in dev staging prod; do \
		echo "Validating $$env environment..."; \
		cd environments/$$env && $(TF) validate && cd ../..; \
	done

# Clean Terraform files and caches
clean:
	@echo "Cleaning Terraform files and caches..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfstate*" -exec rm -f {} + 2>/dev/null || true
	@find . -type f -name "*.tfplan" -exec rm -f {} + 2>/dev/null || true
	@find . -type f -name "plan.out" -exec rm -f {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -exec rm -f {} + 2>/dev/null || true

# Show outputs for an environment
outputs:
	@echo "Showing outputs for $(ENV) environment..."
	@cd environments/$(ENV) && \
		$(TF) output

# Import existing resource
import:
	@if [ -z "$(RESOURCE)" ] || [ -z "$(ID)" ]; then \
		echo "Usage: make import ENV=dev RESOURCE=module.name.resource_type.resource_name ID=resource_id"; \
		exit 1; \
	fi
	@echo "Importing $(RESOURCE) with ID $(ID) in $(ENV) environment..."
	@cd environments/$(ENV) && \
		$(TF) import $(RESOURCE) $(ID)

# Refresh state
refresh:
	@echo "Refreshing state for $(ENV) environment..."
	@cd environments/$(ENV) && \
		$(TF) refresh

# Show specific resource
show:
	@if [ -z "$(RESOURCE)" ]; then \
		echo "Showing all resources in $(ENV) environment..."; \
		cd environments/$(ENV) && $(TF) show; \
	else \
		echo "Showing $(RESOURCE) in $(ENV) environment..."; \
		cd environments/$(ENV) && $(TF) show -target=$(RESOURCE); \
	fi

# Taint resource for recreation
taint:
	@if [ -z "$(RESOURCE)" ]; then \
		echo "Usage: make taint ENV=dev RESOURCE=module.name.resource_type.resource_name"; \
		exit 1; \
	fi
	@echo "Tainting $(RESOURCE) in $(ENV) environment..."
	@cd environments/$(ENV) && \
		$(TF) taint $(RESOURCE)

# Untaint resource
untaint:
	@if [ -z "$(RESOURCE)" ]; then \
		echo "Usage: make untaint ENV=dev RESOURCE=module.name.resource_type.resource_name"; \
		exit 1; \
	fi
	@echo "Untainting $(RESOURCE) in $(ENV) environment..."
	@cd environments/$(ENV) && \
		$(TF) untaint $(RESOURCE)

# Generate documentation
docs:
	@echo "Generating documentation..."
	@terraform-docs markdown . > TERRAFORM_DOCS.md
	@for module in modules/*; do \
		if [ -d "$$module" ]; then \
			echo "Generating docs for $$module..."; \
			terraform-docs markdown $$module > $$module/README.md; \
		fi \
	done

# Check for drift
drift:
	@echo "Checking for drift in $(ENV) environment..."
	@cd environments/$(ENV) && \
		$(TF) plan -detailed-exitcode || echo "Drift detected!"

# Cost estimation (requires Infracost)
cost:
	@echo "Estimating costs for $(ENV) environment..."
	@cd environments/$(ENV) && \
		infracost breakdown --path .

# Security scan (requires tfsec)
security:
	@echo "Running security scan..."
	@tfsec . --exclude-downloaded-modules

# Lint configuration (requires tflint)
lint:
	@echo "Linting Terraform configuration..."
	@tflint --init
	@tflint