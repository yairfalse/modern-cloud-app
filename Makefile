.PHONY: help dev-start dev-stop status setup build test

# Variables
CLUSTER_NAME := modernblog-cluster

# Colors
GREEN := \033[0;32m
BLUE := \033[0;34m
NC := \033[0m

.DEFAULT_GOAL := help

help: ## Show available commands
	@echo '${BLUE}ModernBlog - Simple Development Commands${NC}'
	@echo ''
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  ${GREEN}%-12s${NC} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Run initial setup
	@./setup.sh

dev-start: ## Start development with skaffold
	@echo '${BLUE}Starting development...${NC}'
	@skaffold dev --port-forward

dev-stop: ## Stop development environment
	@echo '${BLUE}Stopping development...${NC}'
	@skaffold delete

status: ## Check cluster and services status
	@echo '${BLUE}Cluster Status:${NC}'
	@kubectl cluster-info
	@echo ''
	@echo '${BLUE}Services:${NC}'
	@kubectl get pods,svc -A

build: ## Build applications
	@echo '${BLUE}Building...${NC}'
	@if [ -f "backend/package.json" ]; then cd backend && npm run build; fi
	@if [ -f "frontend/package.json" ]; then cd frontend && npm run build; fi

test: ## Run tests
	@echo '${BLUE}Running tests...${NC}'
	@if [ -f "backend/package.json" ]; then cd backend && npm test; fi
	@if [ -f "frontend/package.json" ]; then cd frontend && npm test; fi 