# ModernBlog Backend

A clean, professional Go backend for the ModernBlog application.

## Requirements

- Go 1.21 or higher
- PostgreSQL 15 or higher (for local development)
- Make (optional, for using Makefile commands)

## Project Structure

```
backend/
├── cmd/
│   └── server/         # Application entrypoint
│       └── main.go
├── internal/           # Private application code
│   ├── api/           # API handlers and routing
│   └── config/        # Configuration management
├── pkg/               # Public packages (reusable code)
├── build/             # Build artifacts (created on build)
├── go.mod             # Go module definition
├── Makefile           # Build and development commands
└── .dockerignore      # Docker ignore rules
```

## Quick Start

1. **Setup PostgreSQL locally:**
   ```bash
   ../scripts/setup-postgres.sh
   ```

2. **Install dependencies:**
   ```bash
   make deps
   ```

3. **Run the application:**
   ```bash
   make run
   ```
   Or directly with Go:
   ```bash
   go run ./cmd/server
   ```

3. **Build the binary:**
   ```bash
   make build
   ```
   This creates a binary at `./build/modernblog`

## Available Commands

Run `make help` to see all available commands:

- `make build` - Build the application binary
- `make run` - Run the application
- `make test` - Run all tests
- `make lint` - Run linter (golangci-lint or go vet)
- `make clean` - Clean build artifacts
- `make deps` - Download and tidy dependencies
- `make dev` - Run with hot reload (requires air)

## API Endpoints

- `GET /` - Welcome message and API version
- `GET /health` - Health check endpoint

## Environment Variables

- `PORT` - Server port (default: 8080)
- `ENV` - Environment (default: development)
- `DATABASE_URL` - Database connection string (optional)

## Development

For hot reload during development, install [air](https://github.com/cosmtrek/air):
```bash
go install github.com/cosmtrek/air@latest
```

Then run:
```bash
make dev
```

## Testing

Run tests with:
```bash
make test
```

## Linting

For best results, install golangci-lint:
```bash
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

Then run:
```bash
make lint
```