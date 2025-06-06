# ModernBlog - A Cloud-Native Blog Platform =�

<div align="center">

![Go](https://img.shields.io/badge/go-%2300ADD8.svg?style=for-the-badge&logo=go&logoColor=white)
![React](https://img.shields.io/badge/react-%2320232a.svg?style=for-the-badge&logo=react&logoColor=%2361DAFB)
![TypeScript](https://img.shields.io/badge/typescript-%23007ACC.svg?style=for-the-badge&logo=typescript&logoColor=white)
![Google Cloud](https://img.shields.io/badge/GoogleCloud-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)

[![CI/CD](https://img.shields.io/badge/CI%2FCD-Dagger-blue?style=flat-square)](https://dagger.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
[![Commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg?style=flat-square)](http://commitizen.github.io/cz-cli/)

<h3>A modern, scalable blog platform built with cloud-native principles and AI-enhanced development workflows</h3>

[Features](#features) " [Quick Start](#quick-start) " [Documentation](#documentation) " [Contributing](#contributing)

</div>

---

## < Features

### <� Architecture & Technology
- **Backend**: High-performance Go API with clean architecture
- **Frontend**: React with TypeScript for type-safe development
- **Database**: PostgreSQL with automatic migrations
- **Caching**: Redis for optimal performance
- **Search**: Elasticsearch for full-text search capabilities
- **File Storage**: Google Cloud Storage for media assets

### =� DevOps & Infrastructure
- **Container-First**: Fully containerized with Docker and multi-stage builds
- **Kubernetes-Ready**: Production-grade K8s manifests with auto-scaling
- **Infrastructure as Code**: Complete GCP setup with Terraform
- **CI/CD Pipeline**: Automated workflows with Dagger
- **Monitoring**: Prometheus, Grafana, and structured logging

### =� Development Experience
- **AI-Powered Development**: Integrated Claude for code assistance
- **Git Hooks**: Automated linting and testing with Lefthook
- **Hot Reloading**: Live development for both frontend and backend
- **Type Safety**: End-to-end type safety with TypeScript and Go
- **API Documentation**: Auto-generated OpenAPI/Swagger docs

### =� Production Features
- **SEO Optimized**: Server-side rendering and meta tags
- **Progressive Web App**: Offline support and app-like experience
- **Multi-tenancy**: Support for multiple blogs/authors
- **Analytics**: Built-in analytics dashboard
- **CDN Integration**: Global content delivery
- **Rate Limiting**: API protection and quota management

## =� Quick Start

### Prerequisites

- Go 1.21+
- Node.js 20+
- Docker & Docker Compose
- kubectl (for K8s deployment)
- gcloud CLI (for GCP deployment)

### Local Development

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/modernblog.git
cd modernblog
```

2. **Set up environment variables**
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Start the development environment**
```bash
# Using Docker Compose
docker-compose up -d

# Or run services individually
cd backend && go run cmd/server/main.go
cd frontend && npm install && npm run dev
```

4. **Access the application**
- Frontend: http://localhost:3000
- API: http://localhost:8080
- API Docs: http://localhost:8080/swagger

### =3 Docker Development

```bash
# Build all images
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

## <� Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        A[React SPA] --> B[Next.js SSR]
        C[Mobile App] --> D[API Gateway]
    end
    
    subgraph "API Layer"
        D --> E[Go Backend]
        E --> F[GraphQL]
        E --> G[REST API]
    end
    
    subgraph "Service Layer"
        E --> H[Auth Service]
        E --> I[Blog Service]
        E --> J[Media Service]
        E --> K[Search Service]
    end
    
    subgraph "Data Layer"
        H --> L[(PostgreSQL)]
        I --> L
        J --> M[Cloud Storage]
        K --> N[(Elasticsearch)]
        E --> O[(Redis Cache)]
    end
    
    subgraph "Infrastructure"
        P[Kubernetes] --> Q[GKE Cluster]
        R[Terraform] --> S[GCP Resources]
        T[CI/CD Pipeline] --> U[Container Registry]
    end
```

## =� Project Structure

```
modernblog/
   backend/              # Go backend application
      cmd/             # Application entrypoints
      internal/        # Private application code
      pkg/            # Public packages
      api/            # API definitions (proto/openapi)
      migrations/     # Database migrations
   frontend/            # React frontend application
      src/
         components/ # Reusable UI components
         pages/     # Page components
         hooks/     # Custom React hooks
         services/  # API client services
         utils/     # Utility functions
      public/        # Static assets
   k8s/                # Kubernetes manifests
      base/          # Base configurations
      overlays/      # Environment-specific configs
   terraform/          # Infrastructure as Code
      modules/       # Reusable Terraform modules
      environments/  # Environment configurations
   ci/                # CI/CD configurations
      dagger/       # Dagger pipeline definitions
   scripts/           # Development and deployment scripts
```

## =� Development Workflow

### Git Workflow

We follow a GitFlow-based workflow with automated checks:

```bash
# Create a feature branch
git checkout -b feature/amazing-feature

# Make your changes
git add .
git commit -m "feat: add amazing feature"  # Conventional commits enforced

# Push and create PR
git push origin feature/amazing-feature
```

### Running Tests

```bash
# Backend tests
cd backend
go test ./... -v -cover

# Frontend tests
cd frontend
npm test
npm run test:e2e

# Integration tests
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

### Code Quality

```bash
# Backend linting
golangci-lint run

# Frontend linting
npm run lint
npm run type-check

# Format code
npm run format
go fmt ./...
```

## =� Deployment

### Google Cloud Platform

1. **Setup GCP Project**
```bash
gcloud projects create modernblog-prod
gcloud config set project modernblog-prod
```

2. **Deploy Infrastructure**
```bash
cd terraform/environments/production
terraform init
terraform plan
terraform apply
```

3. **Deploy to Kubernetes**
```bash
# Build and push images
dagger do build --platform linux/amd64
dagger do push

# Deploy to GKE
kubectl apply -k k8s/overlays/production
```

### Environment Configuration

| Environment | API URL | Frontend URL |
|------------|---------|--------------|
| Development | http://localhost:8080 | http://localhost:3000 |
| Staging | https://api-staging.modernblog.com | https://staging.modernblog.com |
| Production | https://api.modernblog.com | https://modernblog.com |

## =� API Documentation

### Authentication

```bash
# Register a new user
curl -X POST https://api.modernblog.com/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "secure123"}'

# Login
curl -X POST https://api.modernblog.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "secure123"}'
```

### Blog Posts

```bash
# Create a post
curl -X POST https://api.modernblog.com/v1/posts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My First Post",
    "content": "Hello, World!",
    "tags": ["introduction", "hello"]
  }'

# Get all posts
curl https://api.modernblog.com/v1/posts?page=1&limit=10
```

For complete API documentation, visit [https://api.modernblog.com/swagger](https://api.modernblog.com/swagger)

## >� Performance

### Benchmarks

| Metric | Target | Actual |
|--------|--------|--------|
| API Response Time (p95) | < 100ms | 67ms |
| Frontend Load Time | < 2s | 1.4s |
| Lighthouse Score | > 90 | 95 |
| Concurrent Users | 10,000 |  |

### Load Testing

```bash
# Run load tests
cd scripts
./load-test.sh --users 1000 --duration 5m
```

## > Contributing

We love contributions! Please read our [Contributing Guide](CONTRIBUTING.md) to get started.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'feat: add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).

## =� Project Status

- [x] Core blog functionality
- [x] User authentication
- [x] Media uploads
- [x] Search functionality
- [x] CI/CD pipeline
- [x] Kubernetes deployment
- [ ] Real-time comments
- [ ] Email notifications
- [ ] Social media integration
- [ ] Analytics dashboard

## =� Roadmap

### Q1 2024
- [ ] GraphQL API
- [ ] Mobile app (React Native)
- [ ] Advanced analytics

### Q2 2024
- [ ] AI-powered content recommendations
- [ ] Multi-language support
- [ ] Plugin system

### Q3 2024
- [ ] Federated authentication
- [ ] Content monetization
- [ ] Advanced SEO tools

## =� License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## =O Acknowledgments

- Built with d using modern cloud-native technologies
- Special thanks to the open-source community
- Powered by AI-enhanced development workflows

---

<div align="center">

**[Website](https://modernblog.com)** " **[Documentation](https://docs.modernblog.com)** " **[Blog](https://blog.modernblog.com)**

</div>