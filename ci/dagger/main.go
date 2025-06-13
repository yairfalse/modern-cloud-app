package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"dagger.io/dagger"
)

type TerraformPipeline struct{}

type TerraformResult struct {
	Success   bool              `json:"success"`
	Output    string            `json:"output"`
	ErrorMsg  string            `json:"error_msg,omitempty"`
	Duration  time.Duration     `json:"duration"`
	Artifacts map[string]string `json:"artifacts,omitempty"`
}

type SecurityScanResult struct {
	Issues   []SecurityIssue `json:"issues"`
	Summary  SecuritySummary `json:"summary"`
	Passed   bool            `json:"passed"`
	Severity string          `json:"highest_severity"`
}

type SecurityIssue struct {
	RuleID      string `json:"rule_id"`
	Severity    string `json:"severity"`
	Description string `json:"description"`
	Resource    string `json:"resource"`
	File        string `json:"file"`
	Line        int    `json:"line"`
}

type SecuritySummary struct {
	Total    int `json:"total"`
	Critical int `json:"critical"`
	High     int `json:"high"`
	Medium   int `json:"medium"`
	Low      int `json:"low"`
}

type CostEstimate struct {
	MonthlyCost string            `json:"monthly_cost"`
	Currency    string            `json:"currency"`
	Breakdown   map[string]string `json:"breakdown"`
}

func (tp *TerraformPipeline) getBaseContainer(ctx context.Context, client *dagger.Client, source *dagger.Directory) *dagger.Container {
	return client.Container().
		From("hashicorp/terraform:1.6").
		WithMountedDirectory("/terraform", source).
		WithWorkdir("/terraform").
		WithEnvVariable("TF_IN_AUTOMATION", "true").
		WithEnvVariable("TF_INPUT", "false").
		WithExec([]string{"apk", "add", "--no-cache", "curl", "bash", "jq", "git"})
}

func (tp *TerraformPipeline) getTerraformWithGCP(ctx context.Context, client *dagger.Client, source *dagger.Directory, gcpCredentials *dagger.Secret) *dagger.Container {
	return tp.getBaseContainer(ctx, client, source).
		WithSecretVariable("GOOGLE_APPLICATION_CREDENTIALS_JSON", gcpCredentials).
		WithExec([]string{"sh", "-c", "echo $GOOGLE_APPLICATION_CREDENTIALS_JSON > /tmp/gcp-credentials.json"}).
		WithEnvVariable("GOOGLE_APPLICATION_CREDENTIALS", "/tmp/gcp-credentials.json")
}

func (tp *TerraformPipeline) TerraformValidate(ctx context.Context, source *dagger.Directory) (*TerraformResult, error) {
	client, err := dagger.Connect(ctx, dagger.WithLogOutput(nil))
	if err != nil {
		return nil, err
	}
	defer client.Close()

	start := time.Now()
	
	container := tp.getBaseContainer(ctx, client, source)
	
	// Validate root module
	output, err := container.
		WithExec([]string{"terraform", "validate"}).
		Stdout(ctx)
	
	if err != nil {
		return &TerraformResult{
			Success:  false,
			Output:   output,
			ErrorMsg: err.Error(),
			Duration: time.Since(start),
		}, nil
	}
	
	// Validate each environment
	environments := []string{"dev", "staging", "prod"}
	var allOutput strings.Builder
	allOutput.WriteString("Root module validation:\n" + output + "\n\n")
	
	for _, env := range environments {
		envOutput, err := container.
			WithWorkdir(fmt.Sprintf("/terraform/environments/%s", env)).
			WithExec([]string{"terraform", "init", "-backend=false"}).
			WithExec([]string{"terraform", "validate"}).
			Stdout(ctx)
		
		if err != nil {
			return &TerraformResult{
				Success:  false,
				Output:   allOutput.String() + fmt.Sprintf("Environment %s validation failed:\n%s", env, envOutput),
				ErrorMsg: fmt.Sprintf("Validation failed for environment %s: %v", env, err),
				Duration: time.Since(start),
			}, nil
		}
		
		allOutput.WriteString(fmt.Sprintf("Environment %s validation:\n%s\n\n", env, envOutput))
	}
	
	return &TerraformResult{
		Success:  true,
		Output:   allOutput.String(),
		Duration: time.Since(start),
	}, nil
}

func (tp *TerraformPipeline) TerraformFormat(ctx context.Context, source *dagger.Directory) (*TerraformResult, error) {
	client, err := dagger.Connect(ctx, dagger.WithLogOutput(nil))
	if err != nil {
		return nil, err
	}
	defer client.Close()

	start := time.Now()
	
	container := tp.getBaseContainer(ctx, client, source)
	
	// Check formatting
	checkOutput, err := container.
		WithExec([]string{"terraform", "fmt", "-check", "-recursive", "."}).
		Stdout(ctx)
	
	if err != nil {
		// Format the files
		formatOutput, formatErr := container.
			WithExec([]string{"terraform", "fmt", "-recursive", "."}).
			Stdout(ctx)
		
		if formatErr != nil {
			return &TerraformResult{
				Success:  false,
				Output:   checkOutput + "\n" + formatOutput,
				ErrorMsg: formatErr.Error(),
				Duration: time.Since(start),
			}, nil
		}
		
		return &TerraformResult{
			Success:  true,
			Output:   "Files were formatted:\n" + formatOutput,
			Duration: time.Since(start),
		}, nil
	}
	
	return &TerraformResult{
		Success:  true,
		Output:   "All files are properly formatted:\n" + checkOutput,
		Duration: time.Since(start),
	}, nil
}

func (tp *TerraformPipeline) TerraformPlan(ctx context.Context, source *dagger.Directory, env string, gcpCredentials *dagger.Secret) (*TerraformResult, error) {
	client, err := dagger.Connect(ctx, dagger.WithLogOutput(nil))
	if err != nil {
		return nil, err
	}
	defer client.Close()

	if !tp.isValidEnvironment(env) {
		return &TerraformResult{
			Success:  false,
			ErrorMsg: fmt.Sprintf("Invalid environment: %s. Must be one of: dev, staging, prod", env),
		}, nil
	}

	start := time.Now()
	
	container := tp.getTerraformWithGCP(ctx, client, source, gcpCredentials)
	
	// Initialize and plan
	output, err := container.
		WithWorkdir(fmt.Sprintf("/terraform/environments/%s", env)).
		WithExec([]string{"terraform", "init", "-backend=false"}).
		WithExec([]string{"terraform", "plan", "-out=plan.out", "-detailed-exitcode"}).
		Stdout(ctx)
	
	if err != nil {
		return &TerraformResult{
			Success:  false,
			Output:   output,
			ErrorMsg: err.Error(),
			Duration: time.Since(start),
		}, nil
	}
	
	// Export plan file
	planFile := container.File(fmt.Sprintf("/terraform/environments/%s/plan.out", env))
	planContent, _ := planFile.Contents(ctx)
	
	artifacts := make(map[string]string)
	artifacts[fmt.Sprintf("plan-%s.out", env)] = planContent
	
	return &TerraformResult{
		Success:   true,
		Output:    output,
		Duration:  time.Since(start),
		Artifacts: artifacts,
	}, nil
}

func (tp *TerraformPipeline) TerraformApply(ctx context.Context, source *dagger.Directory, env string, gcpCredentials *dagger.Secret, autoApprove bool) (*TerraformResult, error) {
	client, err := dagger.Connect(ctx, dagger.WithLogOutput(nil))
	if err != nil {
		return nil, err
	}
	defer client.Close()

	if !tp.isValidEnvironment(env) {
		return &TerraformResult{
			Success:  false,
			ErrorMsg: fmt.Sprintf("Invalid environment: %s. Must be one of: dev, staging, prod", env),
		}, nil
	}

	start := time.Now()
	
	container := tp.getTerraformWithGCP(ctx, client, source, gcpCredentials)
	
	workdir := fmt.Sprintf("/terraform/environments/%s", env)
	container = container.WithWorkdir(workdir).
		WithExec([]string{"terraform", "init"})
	
	var output string
	if autoApprove {
		output, err = container.
			WithExec([]string{"terraform", "apply", "-auto-approve"}).
			Stdout(ctx)
	} else {
		// Check if plan file exists first
		_, planErr := container.File(fmt.Sprintf("%s/plan.out", workdir)).Contents(ctx)
		if planErr != nil {
			return &TerraformResult{
				Success:  false,
				ErrorMsg: "No plan file found. Run TerraformPlan first or use auto-approve",
				Duration: time.Since(start),
			}, nil
		}
		
		output, err = container.
			WithExec([]string{"terraform", "apply", "plan.out"}).
			Stdout(ctx)
	}
	
	if err != nil {
		return &TerraformResult{
			Success:  false,
			Output:   output,
			ErrorMsg: err.Error(),
			Duration: time.Since(start),
		}, nil
	}
	
	// Get outputs
	outputsResult, _ := container.
		WithExec([]string{"terraform", "output", "-json"}).
		Stdout(ctx)
	
	artifacts := make(map[string]string)
	artifacts[fmt.Sprintf("outputs-%s.json", env)] = outputsResult
	
	return &TerraformResult{
		Success:   true,
		Output:    output,
		Duration:  time.Since(start),
		Artifacts: artifacts,
	}, nil
}

func (tp *TerraformPipeline) TerraformDestroy(ctx context.Context, source *dagger.Directory, env string, gcpCredentials *dagger.Secret, autoApprove bool) (*TerraformResult, error) {
	client, err := dagger.Connect(ctx, dagger.WithLogOutput(nil))
	if err != nil {
		return nil, err
	}
	defer client.Close()

	if !tp.isValidEnvironment(env) {
		return &TerraformResult{
			Success:  false,
			ErrorMsg: fmt.Sprintf("Invalid environment: %s. Must be one of: dev, staging, prod", env),
		}, nil
	}

	start := time.Now()
	
	container := tp.getTerraformWithGCP(ctx, client, source, gcpCredentials)
	
	workdir := fmt.Sprintf("/terraform/environments/%s", env)
	container = container.WithWorkdir(workdir).
		WithExec([]string{"terraform", "init"})
	
	var output string
	if autoApprove {
		output, err = container.
			WithExec([]string{"terraform", "destroy", "-auto-approve"}).
			Stdout(ctx)
	} else {
		output, err = container.
			WithExec([]string{"terraform", "plan", "-destroy", "-out=destroy.plan"}).
			WithExec([]string{"terraform", "apply", "destroy.plan"}).
			Stdout(ctx)
	}
	
	if err != nil {
		return &TerraformResult{
			Success:  false,
			Output:   output,
			ErrorMsg: err.Error(),
			Duration: time.Since(start),
		}, nil
	}
	
	return &TerraformResult{
		Success:  true,
		Output:   output,
		Duration: time.Since(start),
	}, nil
}

func (tp *TerraformPipeline) SecurityScan(ctx context.Context, source *dagger.Directory) (*SecurityScanResult, error) {
	client, err := dagger.Connect(ctx, dagger.WithLogOutput(nil))
	if err != nil {
		return nil, err
	}
	defer client.Close()
	
	container := client.Container().
		From("aquasec/tfsec:latest").
		WithMountedDirectory("/terraform", source).
		WithWorkdir("/terraform")
	
	output, err := container.
		WithExec([]string{"tfsec", ".", "--format", "json", "--exclude-downloaded-modules"}).
		Stdout(ctx)
	
	if err != nil && !strings.Contains(err.Error(), "exit code 1") {
		return nil, err
	}
	
	var result SecurityScanResult
	if output != "" {
		if jsonErr := json.Unmarshal([]byte(output), &result); jsonErr != nil {
			// If JSON parsing fails, create a basic result
			result = SecurityScanResult{
				Issues:  []SecurityIssue{},
				Summary: SecuritySummary{},
				Passed:  err == nil,
			}
		}
	} else {
		result = SecurityScanResult{
			Issues:  []SecurityIssue{},
			Summary: SecuritySummary{},
			Passed:  true,
		}
	}
	
	return &result, nil
}

func (tp *TerraformPipeline) CostEstimate(ctx context.Context, source *dagger.Directory, env string, gcpCredentials *dagger.Secret) (*CostEstimate, error) {
	client, err := dagger.Connect(ctx, dagger.WithLogOutput(nil))
	if err != nil {
		return nil, err
	}
	defer client.Close()

	if !tp.isValidEnvironment(env) {
		return nil, fmt.Errorf("invalid environment: %s", env)
	}
	
	container := client.Container().
		From("infracost/infracost:latest").
		WithMountedDirectory("/terraform", source).
		WithWorkdir(fmt.Sprintf("/terraform/environments/%s", env)).
		WithSecretVariable("GOOGLE_APPLICATION_CREDENTIALS_JSON", gcpCredentials).
		WithExec([]string{"sh", "-c", "echo $GOOGLE_APPLICATION_CREDENTIALS_JSON > /tmp/gcp-credentials.json"}).
		WithEnvVariable("GOOGLE_APPLICATION_CREDENTIALS", "/tmp/gcp-credentials.json")
	
	output, err := container.
		WithExec([]string{"infracost", "breakdown", "--path", ".", "--format", "json"}).
		Stdout(ctx)
	
	if err != nil {
		return &CostEstimate{
			MonthlyCost: "Error calculating cost",
			Currency:    "USD",
			Breakdown:   map[string]string{"error": err.Error()},
		}, nil
	}
	
	var costData map[string]interface{}
	if jsonErr := json.Unmarshal([]byte(output), &costData); jsonErr != nil {
		return &CostEstimate{
			MonthlyCost: "Error parsing cost data",
			Currency:    "USD",
			Breakdown:   map[string]string{"error": jsonErr.Error()},
		}, nil
	}
	
	monthlyCost := "Unknown"
	if totalMonthlyCost, ok := costData["totalMonthlyCost"].(string); ok {
		monthlyCost = totalMonthlyCost
	}
	
	return &CostEstimate{
		MonthlyCost: monthlyCost,
		Currency:    "USD",
		Breakdown:   map[string]string{"raw": output},
	}, nil
}

func (tp *TerraformPipeline) InfrastructureTest(ctx context.Context, source *dagger.Directory, env string, gcpCredentials *dagger.Secret) (*TerraformResult, error) {
	client, err := dagger.Connect(ctx, dagger.WithLogOutput(nil))
	if err != nil {
		return nil, err
	}
	defer client.Close()

	if !tp.isValidEnvironment(env) {
		return &TerraformResult{
			Success:  false,
			ErrorMsg: fmt.Sprintf("Invalid environment: %s. Must be one of: dev, staging, prod", env),
		}, nil
	}

	start := time.Now()
	
	container := tp.getTerraformWithGCP(ctx, client, source, gcpCredentials)
	
	workdir := fmt.Sprintf("/terraform/environments/%s", env)
	
	// Basic infrastructure tests
	var testResults strings.Builder
	testResults.WriteString("Infrastructure Tests for " + env + " environment:\n\n")
	
	// Test 1: Check if infrastructure is accessible
	testResults.WriteString("1. Checking infrastructure state...\n")
	stateOutput, err := container.
		WithWorkdir(workdir).
		WithExec([]string{"terraform", "init"}).
		WithExec([]string{"terraform", "show", "-json"}).
		Stdout(ctx)
	
	if err != nil {
		testResults.WriteString("   ❌ Failed to get infrastructure state\n")
		return &TerraformResult{
			Success:  false,
			Output:   testResults.String(),
			ErrorMsg: err.Error(),
			Duration: time.Since(start),
		}, nil
	}
	testResults.WriteString("   ✅ Infrastructure state accessible\n")
	
	// Test 2: Validate outputs
	testResults.WriteString("2. Validating infrastructure outputs...\n")
	outputsResult, err := container.
		WithExec([]string{"terraform", "output", "-json"}).
		Stdout(ctx)
	
	if err != nil {
		testResults.WriteString("   ❌ Failed to get infrastructure outputs\n")
	} else {
		testResults.WriteString("   ✅ Infrastructure outputs available\n")
	}
	
	// Test 3: Check for drift
	testResults.WriteString("3. Checking for configuration drift...\n")
	_, err = container.
		WithExec([]string{"terraform", "plan", "-detailed-exitcode"}).
		Stdout(ctx)
	
	if err != nil && strings.Contains(err.Error(), "exit code 2") {
		testResults.WriteString("   ⚠️  Configuration drift detected\n")
	} else if err != nil {
		testResults.WriteString("   ❌ Failed to check for drift\n")
	} else {
		testResults.WriteString("   ✅ No configuration drift detected\n")
	}
	
	artifacts := make(map[string]string)
	artifacts[fmt.Sprintf("infrastructure-state-%s.json", env)] = stateOutput
	artifacts[fmt.Sprintf("infrastructure-outputs-%s.json", env)] = outputsResult
	
	return &TerraformResult{
		Success:   true,
		Output:    testResults.String(),
		Duration:  time.Since(start),
		Artifacts: artifacts,
	}, nil
}

func (tp *TerraformPipeline) FullPipeline(ctx context.Context, source *dagger.Directory, env string, gcpCredentials *dagger.Secret, deployAction string) (map[string]interface{}, error) {
	results := make(map[string]interface{})
	
	// 1. Validate
	validateResult, err := tp.TerraformValidate(ctx, source)
	if err != nil {
		return nil, err
	}
	results["validate"] = validateResult
	
	if !validateResult.Success {
		return results, fmt.Errorf("validation failed")
	}
	
	// 2. Format check
	formatResult, err := tp.TerraformFormat(ctx, source)
	if err != nil {
		return nil, err
	}
	results["format"] = formatResult
	
	// 3. Security scan
	securityResult, err := tp.SecurityScan(ctx, source)
	if err != nil {
		return nil, err
	}
	results["security"] = securityResult
	
	// 4. Cost estimate
	costResult, err := tp.CostEstimate(ctx, source, env, gcpCredentials)
	if err != nil {
		return nil, err
	}
	results["cost"] = costResult
	
	// 5. Plan
	planResult, err := tp.TerraformPlan(ctx, source, env, gcpCredentials)
	if err != nil {
		return nil, err
	}
	results["plan"] = planResult
	
	if !planResult.Success {
		return results, fmt.Errorf("planning failed")
	}
	
	// 6. Deploy (if requested)
	if deployAction == "apply" {
		applyResult, err := tp.TerraformApply(ctx, source, env, gcpCredentials, false)
		if err != nil {
			return nil, err
		}
		results["apply"] = applyResult
		
		if applyResult.Success {
			// 7. Test infrastructure
			testResult, err := tp.InfrastructureTest(ctx, source, env, gcpCredentials)
			if err != nil {
				return nil, err
			}
			results["test"] = testResult
		}
	} else if deployAction == "destroy" {
		destroyResult, err := tp.TerraformDestroy(ctx, source, env, gcpCredentials, false)
		if err != nil {
			return nil, err
		}
		results["destroy"] = destroyResult
	}
	
	return results, nil
}

func (tp *TerraformPipeline) isValidEnvironment(env string) bool {
	validEnvs := map[string]bool{
		"dev":     true,
		"staging": true,
		"prod":    true,
	}
	return validEnvs[env]
}