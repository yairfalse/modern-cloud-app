.PHONY: help dev down build test clean install setup k8s-deploy k8s-delete logs lint format check docker-build docker-push

# Variables
PROJECT_NAME := modernblog
DOCKER_COMPOSE := docker-compose -f dev/docker-compose.dev.yml
KUBECTL := kubectl
KIND := kind
CLUSTER_NAME := modernblog-cluster
NAMESPACE := modernblog

# Colors
GREEN := \033[0;32m
BLUE := \033[0;34m
RED := \033[0;31m
NC := \033[0m

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo '${BLUE}ModernBlog Development Commands${NC}'
	@echo ''
	@echo 'Usage:'
	@echo '  ${GREEN}make${NC} ${BLUE}[target]${NC}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  ${GREEN}%-15s${NC} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install all dependencies
	@echo '${BLUE}Installing dependencies...${NC}'
	@if [ -f "backend/package.json" ]; then cd backend && npm install; fi
	@if [ -f "frontend/package.json" ]; then cd frontend && npm install; fi
	@echo '${GREEN}✓ Dependencies installed${NC}'

setup: ## Run the complete setup script
	@echo '${BLUE}Running setup...${NC}'
	@./setup.sh
	@echo '${GREEN}✓ Setup complete${NC}'

dev: ## Start all development services
	@echo '${BLUE}Starting development services...${NC}'
	@$(DOCKER_COMPOSE) up -d
	@echo '${GREEN}✓ Services started${NC}'
	@echo ''
	@echo 'Services available at:'
	@echo '  - Frontend:    http://localhost:3001'
	@echo '  - Backend API: http://localhost:3000'
	@echo '  - PostgreSQL:  localhost:5432'
	@echo '  - Redis:       localhost:6379'
	@echo '  - MinIO:       http://localhost:9000'
	@echo '  - Prometheus:  http://localhost:9090'
	@echo '  - Grafana:     http://localhost:3000'
	@echo '  - pgAdmin:     http://localhost:5050'

down: ## Stop all development services
	@echo '${BLUE}Stopping development services...${NC}'
	@$(DOCKER_COMPOSE) down
	@echo '${GREEN}✓ Services stopped${NC}'

build: ## Build the application
	@echo '${BLUE}Building application...${NC}'
	@if [ -f "backend/package.json" ]; then cd backend && npm run build; fi
	@if [ -f "frontend/package.json" ]; then cd frontend && npm run build; fi
	@echo '${GREEN}✓ Build complete${NC}'

test: ## Run all tests
	@echo '${BLUE}Running tests...${NC}'
	@if [ -f "backend/package.json" ]; then cd backend && npm test; fi
	@if [ -f "frontend/package.json" ]; then cd frontend && npm test; fi
	@echo '${GREEN}✓ Tests complete${NC}'

lint: ## Run linters
	@echo '${BLUE}Running linters...${NC}'
	@if [ -f "backend/package.json" ]; then cd backend && npm run lint; fi
	@if [ -f "frontend/package.json" ]; then cd frontend && npm run lint; fi
	@echo '${GREEN}✓ Linting complete${NC}'

format: ## Format code
	@echo '${BLUE}Formatting code...${NC}'
	@if [ -f "backend/package.json" ]; then cd backend && npm run format; fi
	@if [ -f "frontend/package.json" ]; then cd frontend && npm run format; fi
	@echo '${GREEN}✓ Formatting complete${NC}'

check: lint test ## Run all checks (lint + test)
	@echo '${GREEN}✓ All checks passed${NC}'

clean: ## Clean build artifacts and dependencies
	@echo '${BLUE}Cleaning...${NC}'
	@rm -rf backend/dist backend/node_modules backend/.turbo
	@rm -rf frontend/dist frontend/node_modules frontend/.next frontend/.turbo
	@rm -rf node_modules .turbo
	@echo '${GREEN}✓ Clean complete${NC}'

logs: ## Show logs from all services
	@$(DOCKER_COMPOSE) logs -f

logs-%: ## Show logs from a specific service (e.g., make logs-postgres)
	@$(DOCKER_COMPOSE) logs -f $*

# Kubernetes targets
k8s-create-cluster: ## Create local Kubernetes cluster
	@echo '${BLUE}Creating Kind cluster...${NC}'
	@$(KIND) create cluster --name $(CLUSTER_NAME) --config dev/kind-config.yaml
	@echo '${GREEN}✓ Cluster created${NC}'

k8s-delete-cluster: ## Delete local Kubernetes cluster
	@echo '${BLUE}Deleting Kind cluster...${NC}'
	@$(KIND) delete cluster --name $(CLUSTER_NAME)
	@echo '${GREEN}✓ Cluster deleted${NC}'

k8s-deploy: ## Deploy application to Kubernetes
	@echo '${BLUE}Deploying to Kubernetes...${NC}'
	@$(KUBECTL) create namespace $(NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(KUBECTL) apply -f k8s/ -n $(NAMESPACE)
	@echo '${GREEN}✓ Deployment complete${NC}'

k8s-delete: ## Delete application from Kubernetes
	@echo '${BLUE}Deleting from Kubernetes...${NC}'
	@$(KUBECTL) delete -f k8s/ -n $(NAMESPACE) --ignore-not-found
	@echo '${GREEN}✓ Deletion complete${NC}'

k8s-status: ## Show Kubernetes deployment status
	@echo '${BLUE}Kubernetes Status:${NC}'
	@$(KUBECTL) get all -n $(NAMESPACE)

# Docker targets
docker-build: ## Build Docker images
	@echo '${BLUE}Building Docker images...${NC}'
	@docker build -t $(PROJECT_NAME)-backend:latest ./backend
	@docker build -t $(PROJECT_NAME)-frontend:latest ./frontend
	@echo '${GREEN}✓ Docker build complete${NC}'

docker-push: ## Push Docker images to registry
	@echo '${BLUE}Pushing Docker images...${NC}'
	@docker push $(PROJECT_NAME)-backend:latest
	@docker push $(PROJECT_NAME)-frontend:latest
	@echo '${GREEN}✓ Docker push complete${NC}'

# Database targets
db-migrate: ## Run database migrations
	@echo '${BLUE}Running migrations...${NC}'
	@cd backend && npm run migrate
	@echo '${GREEN}✓ Migrations complete${NC}'

db-seed: ## Seed database with sample data
	@echo '${BLUE}Seeding database...${NC}'
	@cd backend && npm run seed
	@echo '${GREEN}✓ Database seeded${NC}'

db-reset: ## Reset database (drop, create, migrate, seed)
	@echo '${BLUE}Resetting database...${NC}'
	@cd backend && npm run db:reset
	@echo '${GREEN}✓ Database reset${NC}'

# Monitoring targets
monitor-open: ## Open monitoring dashboards
	@echo '${BLUE}Opening monitoring dashboards...${NC}'
	@open http://localhost:9090 # Prometheus
	@open http://localhost:3000 # Grafana

# Utility targets
env-check: ## Verify environment setup
	@echo '${BLUE}Checking environment...${NC}'
	@./scripts/validate-setup.sh
	@echo '${GREEN}✓ Environment check complete${NC}'

update-deps: ## Update all dependencies
	@echo '${BLUE}Updating dependencies...${NC}'
	@cd backend && npm update
	@cd frontend && npm update
	@echo '${GREEN}✓ Dependencies updated${NC}'

# Git hooks
hooks-install: ## Install git hooks
	@echo '${BLUE}Installing git hooks...${NC}'
	@lefthook install
	@echo '${GREEN}✓ Git hooks installed${NC}'

hooks-run: ## Run git hooks manually
	@echo '${BLUE}Running git hooks...${NC}'
	@lefthook run pre-commit
	@echo '${GREEN}✓ Git hooks complete${NC}' 