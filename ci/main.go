// ModernBlog CI/CD Pipeline - Modular Dagger Implementation
//
// This module provides independent CI/CD functions for ModernBlog infrastructure,
// backend, and frontend components. Each module can be run independently,
// allowing for flexible pipeline execution and parallel processing.

package main

import (
	"context"
	"fmt"
	"dagger/modernblog-ci/internal/dagger"
)

type ModernblogCi struct{}

// Infrastructure Module - Terraform operations
type Infrastructure struct{}

// TerraformPlan runs terraform plan for infrastructure changes
func (m *ModernblogCi) TerraformPlan(ctx context.Context, source *dagger.Directory, projectId string, region string, namePrefix string) (string, error) {
	// Create terraform.tfvars content
	tfvarsContent := fmt.Sprintf(`project_id = "%s"
region     = "%s"
name_prefix = "%s"
`, projectId, region, namePrefix)

	terraform := dag.Container().
		From("hashicorp/terraform:latest").
		WithDirectory("/workspace", source).
		WithWorkdir("/workspace/terraform").
		WithNewFile("/workspace/terraform/terraform.tfvars", tfvarsContent).
		WithExec([]string{"terraform", "init", "-backend=false"})

	output, err := terraform.
		WithExec([]string{"terraform", "plan", "-var-file=terraform.tfvars", "-out=tfplan"}).
		Stdout(ctx)
	
	if err != nil {
		return "", fmt.Errorf("terraform plan failed: %w", err)
	}
	
	return output, nil
}

// TerraformValidate validates terraform configuration
func (m *ModernblogCi) TerraformValidate(ctx context.Context, source *dagger.Directory) (string, error) {
	terraform := dag.Container().
		From("hashicorp/terraform:latest").
		WithDirectory("/workspace", source).
		WithWorkdir("/workspace/terraform").
		WithExec([]string{"terraform", "init", "-backend=false"})

	// Format check
	formatCheck, _ := terraform.
		WithExec([]string{"terraform", "fmt", "-check", "-recursive"}).
		Stdout(ctx)

	// Validation
	validateOutput, err := terraform.
		WithExec([]string{"terraform", "validate"}).
		Stdout(ctx)
	
	if err != nil {
		return "", fmt.Errorf("terraform validation failed: %w", err)
	}
	
	return fmt.Sprintf("Format Check:\n%s\n\nValidation:\n%s", formatCheck, validateOutput), nil
}

// TerraformApply applies terraform changes
func (m *ModernblogCi) TerraformApply(ctx context.Context, source *dagger.Directory, autoApprove bool) (string, error) {
	terraform := dag.Container().
		From("hashicorp/terraform:latest").
		WithDirectory("/workspace", source).
		WithWorkdir("/workspace/terraform").
		WithExec([]string{"terraform", "init"})

	args := []string{"terraform", "apply"}
	if autoApprove {
		args = append(args, "-auto-approve")
	}

	output, err := terraform.
		WithExec(args).
		Stdout(ctx)
	
	if err != nil {
		return "", fmt.Errorf("terraform apply failed: %w", err)
	}
	
	return output, nil
}

// Backend Module - Go application operations
type Backend struct{}

// BuildBackend builds the Go backend application
func (m *ModernblogCi) BuildBackend(ctx context.Context, source *dagger.Directory) (*dagger.Container, error) {
	backend := dag.Container().
		From("golang:1.24-alpine").
		WithDirectory("/app", source).
		WithWorkdir("/app/backend").
		WithExec([]string{"go", "mod", "download"}).
		WithExec([]string{"go", "build", "-o", "server", "./cmd/server"})

	// Verify build succeeded
	_, err := backend.File("/app/backend/server").Contents(ctx)
	if err != nil {
		return nil, fmt.Errorf("backend build failed: %w", err)
	}

	return backend, nil
}

// TestBackend runs backend tests
func (m *ModernblogCi) TestBackend(ctx context.Context, source *dagger.Directory) (string, error) {
	testOutput, err := dag.Container().
		From("golang:1.24-alpine").
		WithDirectory("/app", source).
		WithWorkdir("/app/backend").
		WithExec([]string{"go", "mod", "download"}).
		WithExec([]string{"go", "test", "-v", "./..."}).
		Stdout(ctx)
	
	if err != nil {
		return "", fmt.Errorf("backend tests failed: %w", err)
	}
	
	return testOutput, nil
}

// DeployBackend creates a deployable container for the backend
func (m *ModernblogCi) DeployBackend(ctx context.Context, source *dagger.Directory, registry string, tag string) (string, error) {
	// Build the backend first
	buildContainer, err := m.BuildBackend(ctx, source)
	if err != nil {
		return "", err
	}

	// Create minimal runtime container
	runtime := dag.Container().
		From("alpine:latest").
		WithFile("/app/server", buildContainer.File("/app/backend/server")).
		WithExec([]string{"chmod", "+x", "/app/server"}).
		WithEntrypoint([]string{"/app/server"}).
		WithExposedPort(8080)

	// Publish to registry if provided
	if registry != "" && tag != "" {
		addr, err := runtime.Publish(ctx, fmt.Sprintf("%s:%s", registry, tag))
		if err != nil {
			return "", fmt.Errorf("failed to publish backend image: %w", err)
		}
		return addr, nil
	}

	return "Backend container built successfully", nil
}

// Frontend Module - React application operations
type Frontend struct{}

// BuildFrontend builds the React frontend application
func (m *ModernblogCi) BuildFrontend(ctx context.Context, source *dagger.Directory) (*dagger.Container, error) {
	frontend := dag.Container().
		From("node:20-alpine").
		WithDirectory("/app", source).
		WithWorkdir("/app/frontend").
		WithExec([]string{"npm", "ci"}).
		WithExec([]string{"npm", "run", "build"})

	// Verify build succeeded
	_, err := frontend.Directory("/app/frontend/dist").Entries(ctx)
	if err != nil {
		return nil, fmt.Errorf("frontend build failed: %w", err)
	}

	return frontend, nil
}

// TestFrontend runs frontend tests
func (m *ModernblogCi) TestFrontend(ctx context.Context, source *dagger.Directory) (string, error) {
	testOutput, err := dag.Container().
		From("node:20-alpine").
		WithDirectory("/app", source).
		WithWorkdir("/app/frontend").
		WithExec([]string{"npm", "ci"}).
		WithExec([]string{"npm", "run", "test", "--", "--run"}).
		Stdout(ctx)
	
	if err != nil {
		return "", fmt.Errorf("frontend tests failed: %w", err)
	}
	
	return testOutput, nil
}

// DeployFrontend creates a deployable container for the frontend
func (m *ModernblogCi) DeployFrontend(ctx context.Context, source *dagger.Directory, registry string, tag string) (string, error) {
	// Build the frontend first
	buildContainer, err := m.BuildFrontend(ctx, source)
	if err != nil {
		return "", err
	}

	// Create nginx container with built assets
	runtime := dag.Container().
		From("nginx:alpine").
		WithDirectory("/usr/share/nginx/html", buildContainer.Directory("/app/frontend/dist")).
		WithExposedPort(80)

	// Publish to registry if provided
	if registry != "" && tag != "" {
		addr, err := runtime.Publish(ctx, fmt.Sprintf("%s:%s", registry, tag))
		if err != nil {
			return "", fmt.Errorf("failed to publish frontend image: %w", err)
		}
		return addr, nil
	}

	return "Frontend container built successfully", nil
}

// Utility functions for running multiple operations

// RunAll executes all CI/CD operations in parallel where possible
func (m *ModernblogCi) RunAll(ctx context.Context, source *dagger.Directory) (string, error) {
	results := make(chan string, 3)
	errors := make(chan error, 3)

	// Run infrastructure validation in parallel
	go func() {
		result, err := m.TerraformValidate(ctx, source)
		if err != nil {
			errors <- fmt.Errorf("infrastructure validation: %w", err)
			return
		}
		results <- fmt.Sprintf("✓ Infrastructure validation completed\n%s", result)
	}()

	// Run backend tests in parallel
	go func() {
		result, err := m.TestBackend(ctx, source)
		if err != nil {
			errors <- fmt.Errorf("backend tests: %w", err)
			return
		}
		results <- fmt.Sprintf("✓ Backend tests completed\n%s", result)
	}()

	// Run frontend tests in parallel
	go func() {
		result, err := m.TestFrontend(ctx, source)
		if err != nil {
			errors <- fmt.Errorf("frontend tests: %w", err)
			return
		}
		results <- fmt.Sprintf("✓ Frontend tests completed\n%s", result)
	}()

	// Collect results
	var allResults []string
	var allErrors []error

	for i := 0; i < 3; i++ {
		select {
		case result := <-results:
			allResults = append(allResults, result)
		case err := <-errors:
			allErrors = append(allErrors, err)
		}
	}

	// Report results
	output := "=== ModernBlog CI/CD Pipeline Results ===\n\n"
	
	for _, result := range allResults {
		output += result + "\n\n"
	}

	if len(allErrors) > 0 {
		output += "=== Errors ===\n"
		for _, err := range allErrors {
			output += fmt.Sprintf("✗ %v\n", err)
		}
		return output, fmt.Errorf("%d operations failed", len(allErrors))
	}

	return output + "\n✓ All operations completed successfully!", nil
}