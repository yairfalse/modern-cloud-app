.PHONY: help dev-start dev-stop status setup build test

# Variables
CLUSTER_NAME := modernblog-cluster

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

.DEFAULT_GOAL := help

help: ## Show available commands
	@echo 'ModernBlog - Simple Development Commands'
	@echo ''
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Run initial setup
	@./setup.sh

dev-start: ## Start development with skaffold
	@echo 'Starting development...'
	@skaffold dev --port-forward

dev-stop: ## Stop development environment
	@echo 'Stopping development...'
	@skaffold delete

status: ## Check cluster and services status
	@echo 'Cluster Status:'
	@kubectl cluster-info
	@echo ''
	@echo 'Services:'
	@kubectl get pods,svc -A

build: ## Build applications
	@echo 'Building applications...'
	@if [ -f "backend/package.json" ]; then cd backend && npm run build; fi
	@if [ -f "frontend/package.json" ]; then cd frontend && npm run build; fi

test: ## Run tests
	@echo 'Running tests...'
	@if [ -f "backend/package.json" ]; then cd backend && npm test; fi
	@if [ -f "frontend/package.json" ]; then cd frontend && npm test; fi

clean: ## Clean up resources
	@echo 'Cleaning up...'
	@kind delete cluster --name $(CLUSTER_NAME) || true
	@docker system prune -f 