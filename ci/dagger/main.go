package main

import (
	"context"
	"fmt"
	"strings"
	"time"

	"dagger/backend-pipeline/internal/dagger"
)

// BackendPipeline provides dagger functions for backend CI/CD
type BackendPipeline struct{}

// Build builds the Go application
func (m *BackendPipeline) Build(ctx context.Context, source *dagger.Directory) (string, error) {
	start := time.Now()

	container := dag.Container().
		From("golang:1.21-alpine").
		WithMountedDirectory("/app", source).
		WithWorkdir("/app/backend").
		WithExec([]string{"apk", "add", "--no-cache", "git", "gcc", "musl-dev"})

	// Build binary
	output, err := container.
		WithExec([]string{"go", "build", "-ldflags", "-s -w", "-o", "app", "."}).
		Stdout(ctx)

	duration := time.Since(start)
	
	if err != nil {
		return fmt.Sprintf("❌ Build failed in %v: %v", duration, err), nil
	}

	return fmt.Sprintf("✅ Build successful in %v\nOutput: %s", duration, output), nil
}

// Test runs Go tests with coverage
func (m *BackendPipeline) Test(ctx context.Context, source *dagger.Directory) (string, error) {
	start := time.Now()

	container := dag.Container().
		From("golang:1.21-alpine").
		WithMountedDirectory("/app", source).
		WithWorkdir("/app/backend").
		WithExec([]string{"apk", "add", "--no-cache", "git", "gcc", "musl-dev"})

	// Run tests with coverage
	testOutput, testErr := container.
		WithExec([]string{"go", "test", "-v", "-race", "-coverprofile=coverage.out", "./..."}).
		Stdout(ctx)

	duration := time.Since(start)
	
	if testErr != nil {
		return fmt.Sprintf("❌ Tests failed in %v: %v\nOutput: %s", duration, testErr, testOutput), nil
	}

	// Get coverage report
	coverageOutput, _ := container.
		WithExec([]string{"go", "tool", "cover", "-func=coverage.out"}).
		Stdout(ctx)

	// Simple parsing for coverage
	coverage := 0.0
	if coverageLines := strings.Split(coverageOutput, "\n"); len(coverageLines) > 0 {
		lastLine := coverageLines[len(coverageLines)-2]
		if strings.Contains(lastLine, "total:") {
			parts := strings.Fields(lastLine)
			if len(parts) >= 3 {
				coverageStr := strings.TrimSuffix(parts[2], "%")
				fmt.Sscanf(coverageStr, "%f", &coverage)
			}
		}
	}

	return fmt.Sprintf("✅ Tests passed in %v\nCoverage: %.1f%%\nOutput: %s", duration, coverage, testOutput), nil
}

// Lint runs golangci-lint on the backend code
func (m *BackendPipeline) Lint(ctx context.Context, source *dagger.Directory) (string, error) {
	start := time.Now()

	container := dag.Container().
		From("golangci/golangci-lint:v1.55-alpine").
		WithMountedDirectory("/app", source).
		WithWorkdir("/app/backend")

	output, err := container.
		WithExec([]string{"golangci-lint", "run", "--timeout", "5m"}).
		Stdout(ctx)

	duration := time.Since(start)

	if err != nil {
		return fmt.Sprintf("❌ Lint failed in %v: %v\nOutput: %s", duration, err, output), nil
	}

	return fmt.Sprintf("✅ Lint passed in %v\nOutput: %s", duration, output), nil
}

// Container builds a Docker image for the backend
func (m *BackendPipeline) Container(ctx context.Context, source *dagger.Directory) (string, error) {
	start := time.Now()

	// Build container using Dockerfile
	container := dag.Container().Build(source.Directory("backend"))

	// Export to local Docker daemon
	tag := "modern-blog:latest"
	_, err := container.Export(ctx, tag)
	
	duration := time.Since(start)

	if err != nil {
		return fmt.Sprintf("❌ Container build failed in %v: %v", duration, err), nil
	}

	return fmt.Sprintf("✅ Container built successfully in %v\nTag: %s", duration, tag), nil
}

// FullPipeline runs the complete backend CI/CD pipeline
func (m *BackendPipeline) FullPipeline(ctx context.Context, source *dagger.Directory) (string, error) {
	output := "🚀 Backend Pipeline Results:\n\n"
	
	// 1. Lint
	lintResult, err := m.Lint(ctx, source)
	if err != nil {
		return "", err
	}
	output += "1. Lint:\n" + lintResult + "\n\n"
	
	// 2. Test
	testResult, err := m.Test(ctx, source)
	if err != nil {
		return "", err
	}
	output += "2. Test:\n" + testResult + "\n\n"
	
	// 3. Build
	buildResult, err := m.Build(ctx, source)
	if err != nil {
		return "", err
	}
	output += "3. Build:\n" + buildResult + "\n\n"
	
	// 4. Container
	containerResult, err := m.Container(ctx, source)
	if err != nil {
		return "", err
	}
	output += "4. Container:\n" + containerResult + "\n\n"
	
	output += "🎉 Pipeline completed successfully!"
	
	return output, nil
}