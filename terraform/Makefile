# Makefile for ModernBlog Terraform Infrastructure

.PHONY: help init plan apply destroy fmt validate clean

# Default environment
ENV ?= dev

# Terraform command
TF = terraform

# Help target
help:
	@echo "ModernBlog Terraform Infrastructure"
	@echo ""
	@echo "Usage: make [target] ENV=[dev|staging|prod]"
	@echo ""
	@echo "Targets:"
	@echo "  init      - Initialize Terraform for the specified environment"
	@echo "  plan      - Create execution plan for the specified environment"
	@echo "  apply     - Apply changes to the specified environment"
	@echo "  destroy   - Destroy infrastructure in the specified environment"
	@echo "  fmt       - Format Terraform files"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  clean     - Clean Terraform files and caches"
	@echo ""
	@echo "Examples:"
	@echo "  make init ENV=dev"
	@echo "  make plan ENV=staging"
	@echo "  make apply ENV=prod"

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