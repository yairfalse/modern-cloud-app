# ModernBlog

A modern cloud-native blog platform built for learning cloud technologies through hands-on development.

## Overview

ModernBlog is a full-stack application that demonstrates modern cloud development practices. It features a Go REST API backend with SQLite database, React frontend with TypeScript, Dagger CI/CD pipeline, and supports both local development and cloud deployment via Terraform.

## Features

### Backend (Go)
- ✅ REST API with Gin framework
- ✅ SQLite database with automatic table creation
- ✅ CRUD operations for blog posts
- ✅ Comprehensive test suite with 95%+ coverage
- ✅ Dockerized for container deployment
- ✅ Linting with golangci-lint (zero issues)

### Frontend (React + TypeScript)
- ✅ Modern React 19 with TypeScript
- ✅ Vite for fast development and building
- ✅ Tailwind CSS for styling
- ✅ Comprehensive TypeScript type definitions
- ✅ ESLint and Prettier for code quality
- ✅ Vitest for testing

### CI/CD (Dagger)
- ✅ Automated testing pipeline
- ✅ Code linting and formatting
- ✅ Container image building
- ✅ Cross-platform support (Linux, macOS, Windows)

### Infrastructure (Terraform)
- ✅ Google Cloud Platform deployment
- ✅ Kubernetes (GKE) orchestration
- ✅ Cloud SQL database
- ✅ Monitoring and logging setup
- ✅ Modular architecture for reusability

## Prerequisites

Before you begin, ensure you have the following installed:

- **Go** (1.21+) - for backend development
- **Node.js** (18+) - for frontend development
- **Docker** - for cyfgwrite ontainerization
- **Dagger** - for CI/CD automation
- **Terraform** (optional) - for cloud deployment
- **kubectl** (optional) - for Kubernetes deployment

## Quick Start

### Option 1: Local Development (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/modern-cloud-app.git
   cd modern-cloud-app
   ```

2. **Install dependencies and setup**
   ```bash
   ./setup.sh
   ```

3. **Start the backend** (in one terminal)
   ```bash
   cd backend
   go run main.go
   ```

4. **Start the frontend** (in another terminal)
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

5. **Access the application**
   - Frontend: http://localhost:5173
   - Backend API: http://localhost:8080
   - Health check: http://localhost:8080/health

### Option 2: Using Dagger CI/CD

1. **Install Dagger**
   ```bash
   curl -L https://dl.dagger.io/dagger/install.sh | DAGGER_VERSION=0.9.3 sh
   sudo mv bin/dagger /usr/local/bin
   ```

2. **Run the pipeline**
   ```bash
   cd ci/dagger
   dagger call test --source=../..
   dagger call lint --source=../..
   dagger call build --source=../..
   ```

## Development Workflow

### Making Changes

1. **Backend development**
   - Edit files in `backend/`
   - The API uses SQLite database stored in `backend/blog.db`
   - Run tests: `cd backend && go test`
   - Lint code: `cd backend && golangci-lint run`

2. **Frontend development**
   - Edit files in `frontend/src/`
   - Hot reload is enabled by default with Vite
   - Run tests: `cd frontend && npm test`
   - Lint code: `cd frontend && npm run lint`

3. **Using TypeScript types**
   - Backend API types are defined in `frontend/src/types/`
   - `index.ts` - Core entities (BlogPost, User)
   - `api.ts` - API request/response types
   - `common.ts` - Utility types

### Testing

```bash
# Backend tests
cd backend
go test -v

# Frontend tests  
cd frontend
npm run test

# CI/CD pipeline tests
cd ci/dagger
dagger call test --source=../..
```

### API Endpoints

The backend provides a REST API:

```
GET    /health              - Health check
GET    /posts               - Get all blog posts
POST   /posts               - Create a new post
PUT    /posts/:id           - Update a post
DELETE /posts/:id           - Delete a post
```

## Project Structure

```
modern-cloud-app/
├── backend/              # Go REST API server
│   ├── main.go          # Main application entry point
│   ├── main_test.go     # Comprehensive test suite
│   ├── go.mod           # Go module dependencies
│   ├── Dockerfile       # Container configuration
│   └── blog.db          # SQLite database
├── frontend/             # React + TypeScript application
│   ├── src/
│   │   ├── types/       # TypeScript type definitions
│   │   ├── components/  # React components
│   │   ├── pages/       # Page components
│   │   └── hooks/       # Custom React hooks
│   ├── package.json     # Node.js dependencies
│   └── vite.config.ts   # Vite build configuration
├── ci/
│   └── dagger/          # Dagger CI/CD pipeline
│       ├── main.go      # Pipeline definitions
│       └── examples/    # Usage examples
├── terraform/           # Infrastructure as Code
│   ├── main.tf         # Main Terraform config
│   └── modules/        # Reusable Terraform modules
├── scripts/             # Setup and utility scripts
├── docs/               # Documentation
└── k8s/                # Kubernetes manifests
```

## Common Commands

### Local Development
```bash
# Setup project
./setup.sh

# Backend
cd backend
go run main.go                    # Start server
go test -v                        # Run tests
golangci-lint run                 # Lint code

# Frontend  
cd frontend
npm install                       # Install dependencies
npm run dev                       # Start dev server
npm run build                     # Build for production
npm run test                      # Run tests
npm run lint                      # Lint code
```

### CI/CD with Dagger
```bash
cd ci/dagger

# Development workflow
dagger call test --source=../..   # Run all tests
dagger call lint --source=../..   # Lint all code
dagger call build --source=../..  # Build applications

# Production workflow
dagger call publish --source=../.. # Build and publish containers
```

### Cloud Deployment
```bash
cd terraform

# Initialize and plan
terraform init
terraform plan

# Deploy infrastructure
terraform apply

# Destroy infrastructure
terraform destroy
```

## Troubleshooting

### Backend Issues

**Port already in use**
```bash
# Check what's using port 8080
lsof -i :8080
# Kill the process
kill -9 <PID>
```

**Database issues**
```bash
# Reset SQLite database
rm backend/blog.db
# Restart the backend - it will recreate the database
```

**Go module issues**
```bash
cd backend
go mod tidy
go mod download
```

### Frontend Issues

**Node.js issues**
```bash
cd frontend
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

**Port 5173 in use**
```bash
# Check what's using port 5173  
lsof -i :5173
# Kill the process
kill -9 <PID>
```

### Dagger Issues

**Dagger not found**
```bash
# Install Dagger
curl -L https://dl.dagger.io/dagger/install.sh | DAGGER_VERSION=0.9.3 sh
sudo mv bin/dagger /usr/local/bin
```

**Pipeline failures**
```bash
# Check Dagger version
dagger version

# Run with verbose output
dagger call test --source=../.. --verbose
```

### General Debugging

Check the documentation for more help:
- [Architecture Overview](docs/ARCHITECTURE.md)
- [Daily Workflow](docs/DAILY-WORKFLOW.md) 
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.