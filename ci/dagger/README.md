# Terraform Dagger Pipeline

A comprehensive Dagger pipeline for managing ModernBlog Terraform infrastructure on Google Cloud Platform.

## Features

- **Environment Support**: Supports dev, staging, and prod environments
- **Terraform Operations**: Validate, plan, apply, destroy, and format
- **Security Scanning**: Integrated tfsec security scanning
- **Cost Estimation**: Infrastructure cost estimation with Infracost
- **Infrastructure Testing**: Post-deployment validation
- **GCP Authentication**: Secure credential handling
- **GitHub Actions Integration**: Ready-to-use CI/CD workflows

## Prerequisites

1. **Dagger CLI**: Install from https://dagger.io
2. **Go 1.22+**: Required for running the pipeline
3. **GCP Service Account**: With appropriate permissions for your project
4. **Terraform**: For local development (optional, as Dagger uses containerized Terraform)

## Quick Start

### Local Usage

1. **Initialize the Dagger module**:
   ```bash
   cd ci/dagger
   dagger develop
   ```

2. **Set up GCP credentials**:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
   ```

3. **Run operations**:
   ```bash
   # Validate Terraform configuration
   dagger call terraform-validate --source=../../terraform
   
   # Format Terraform files
   dagger call terraform-format --source=../../terraform
   
   # Run security scan
   dagger call security-scan --source=../../terraform
   
   # Plan for development environment
   dagger call terraform-plan --source=../../terraform --env=dev --gcp-credentials=file:/path/to/service-account.json
   
   # Apply to development (with auto-approve)
   dagger call terraform-apply --source=../../terraform --env=dev --gcp-credentials=file:/path/to/service-account.json --auto-approve=true
   
   # Run infrastructure tests
   dagger call infrastructure-test --source=../../terraform --env=dev --gcp-credentials=file:/path/to/service-account.json
   
   # Get cost estimate
   dagger call cost-estimate --source=../../terraform --env=dev --gcp-credentials=file:/path/to/service-account.json
   
   # Run full pipeline
   dagger call full-pipeline --source=../../terraform --env=dev --gcp-credentials=file:/path/to/service-account.json --deploy-action=plan
   ```

### GitHub Actions

The pipeline includes a comprehensive GitHub Actions workflow that:

1. **On Pull Requests**: Runs validation, security scanning, and planning
2. **On Push to develop**: Automatically deploys to development environment
3. **On Push to main**: Automatically deploys to staging environment
4. **Manual Dispatch**: Allows manual operations on any environment

#### Required Secrets

Set up these secrets in your GitHub repository:

- `GCP_SA_KEY`: Your GCP service account JSON key

#### Environment Protection

Configure GitHub environment protection rules:
- **development**: Auto-deploy from develop branch
- **staging**: Auto-deploy from main branch  
- **production**: Manual approval required

## Available Functions

### Core Terraform Operations

#### `TerraformValidate(source Directory) *TerraformResult`
Validates all Terraform configurations including root module and all environments.

#### `TerraformFormat(source Directory) *TerraformResult`
Checks and formats Terraform files according to canonical style.

#### `TerraformPlan(source Directory, env string, gcpCredentials Secret) *TerraformResult`
Creates execution plan for specified environment.

#### `TerraformApply(source Directory, env string, gcpCredentials Secret, autoApprove bool) *TerraformResult`
Applies Terraform changes to infrastructure.

#### `TerraformDestroy(source Directory, env string, gcpCredentials Secret, autoApprove bool) *TerraformResult`
Destroys Terraform-managed infrastructure.

### Security and Quality

#### `SecurityScan(source Directory) *SecurityScanResult`
Runs tfsec security scanning on Terraform configurations.

#### `CostEstimate(source Directory, env string, gcpCredentials Secret) *CostEstimate`
Estimates infrastructure costs using Infracost.

#### `InfrastructureTest(source Directory, env string, gcpCredentials Secret) *TerraformResult`
Tests infrastructure after deployment for basic functionality.

### Orchestration

#### `FullPipeline(source Directory, env string, gcpCredentials Secret, deployAction string) map[string]interface{}`
Runs complete pipeline including validation, security scan, cost estimation, planning, and optional deployment.

## Integration with Existing Makefile

The Dagger pipeline complements your existing Makefile by providing:

- **Containerized execution**: Consistent environment across different systems
- **Enhanced security**: Built-in security scanning and cost estimation
- **CI/CD integration**: Ready-to-use GitHub Actions workflows
- **Artifact management**: Automatic generation and storage of plans and outputs

You can continue using the Makefile for local development while leveraging Dagger for CI/CD.

## Security Considerations

1. **Credentials**: Never commit GCP credentials to the repository
2. **Secrets**: Use GitHub Secrets for sensitive information
3. **Environment isolation**: Each environment uses separate state and credentials
4. **Security scanning**: Automatic tfsec scanning prevents security misconfigurations
5. **Approval gates**: Production deployments require manual approval

## Troubleshooting

### Common Issues

1. **Authentication failures**: Ensure GCP service account has required permissions
2. **Missing dependencies**: Install required tools (Dagger, Go)
3. **State lock conflicts**: Ensure no concurrent operations on the same environment
4. **Resource quota limits**: Check GCP quotas for your project

### Debug Mode

Enable verbose logging:
```bash
export DAGGER_LOG_LEVEL=debug
dagger call terraform-plan --source=../../terraform --env=dev --gcp-credentials=file:/path/to/service-account.json
```

## Contributing

1. Test locally before submitting PRs
2. Ensure all security scans pass
3. Update documentation for new features
4. Follow Go coding standards

## Cost Management

The pipeline includes cost estimation to help manage infrastructure expenses:

- **Development**: Minimal resources for testing
- **Staging**: Production-like but smaller scale
- **Production**: Full-scale infrastructure

Review cost estimates before applying changes to production environments.