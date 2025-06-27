# ModernBlog Local Development Makefile
# Simple commands that actually work

.PHONY: help dev stop logs restart clean status db-shell backend-logs frontend-logs

# Default target
help:
	@echo "ModernBlog Development Commands"
	@echo "=============================="
	@echo ""
	@echo "Main commands:"
	@echo "  make dev        - Start development environment with hot reload"
	@echo "  make stop       - Stop all services"
	@echo "  make logs       - View all application logs"
	@echo "  make restart    - Restart services"
	@echo "  make clean      - Remove everything (WARNING: deletes data)"
	@echo ""
	@echo "Debugging commands:"
	@echo "  make status     - Show status of all services"
	@echo "  make db-shell   - Connect to PostgreSQL"
	@echo "  make backend-logs  - View backend logs only"
	@echo "  make frontend-logs - View frontend logs only"

# Start development environment
dev:
	@echo "Starting ModernBlog development environment..."
	@echo "============================================"
	@echo "Starting Skaffold (hot reload enabled)..."
	@echo ""
	@echo "App will be available at:"
	@echo "  - Frontend: http://localhost:3000"
	@echo "  - Backend API: http://localhost:8080"
	@echo "  - PostgreSQL: localhost:5432"
	@echo ""
	@skaffold dev --port-forward

# Stop all services
stop:
	@echo "Stopping ModernBlog services..."
	@skaffold delete || true
	@echo "✓ All services stopped"

# View logs
logs:
	@echo "Viewing application logs..."
	@kubectl logs -n modernblog-dev -l app=modernblog --all-containers=true -f --tail=50

# Restart services
restart:
	@echo "Restarting services..."
	@$(MAKE) stop
	@sleep 2
	@$(MAKE) dev

# Clean everything (including data)
clean:
	@echo "WARNING: This will delete all data!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@echo "Cleaning up..."
	@skaffold delete || true
	@kind delete cluster --name modernblog-dev || true
	@echo "✓ Cleanup complete"

# Show status of all services
status:
	@echo "ModernBlog Service Status"
	@echo "========================"
	@echo ""
	@echo "Kubernetes Pods:"
	@kubectl get pods -n modernblog-dev
	@echo ""
	@echo "Port Forwards:"
	@echo "  - Frontend: http://localhost:3000"
	@echo "  - Backend API: http://localhost:8080"
	@echo "  - PostgreSQL: localhost:5432"

# Connect to PostgreSQL
db-shell:
	@echo "Connecting to PostgreSQL..."
	@echo "Database: modernblog_dev"
	@echo "User: modernblog"
	@echo ""
	@kubectl exec -it -n modernblog-dev deploy/postgres -- psql -U modernblog -d modernblog_dev

# View backend logs only
backend-logs:
	@kubectl logs -n modernblog-dev -l app=modernblog-backend -f --tail=50

# View frontend logs only
frontend-logs:
	@kubectl logs -n modernblog-dev -l app=modernblog-frontend -f --tail=50