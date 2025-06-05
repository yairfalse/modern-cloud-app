#!/bin/bash

# ModernBlog Terraform Dagger Pipeline - Local Usage Examples
# Make sure you have Dagger CLI installed and GCP credentials configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_SOURCE="../../terraform"
ENVIRONMENT="${ENVIRONMENT:-dev}"
GCP_CREDENTIALS_PATH="${GOOGLE_APPLICATION_CREDENTIALS}"

echo -e "${BLUE}ModernBlog Terraform Dagger Pipeline${NC}"
echo "======================================"
echo "Environment: $ENVIRONMENT"
echo "Terraform Source: $TERRAFORM_SOURCE"
echo "GCP Credentials: $GCP_CREDENTIALS_PATH"
echo ""

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    if ! command -v dagger &> /dev/null; then
        echo -e "${RED}Dagger CLI not found. Please install from https://dagger.io${NC}"
        exit 1
    fi
    
    if ! command -v go &> /dev/null; then
        echo -e "${RED}Go not found. Please install Go 1.22+${NC}"
        exit 1
    fi
    
    if [ -z "$GCP_CREDENTIALS_PATH" ]; then
        echo -e "${RED}GCP credentials not configured. Set GOOGLE_APPLICATION_CREDENTIALS${NC}"
        exit 1
    fi
    
    if [ ! -f "$GCP_CREDENTIALS_PATH" ]; then
        echo -e "${RED}GCP credentials file not found: $GCP_CREDENTIALS_PATH${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Prerequisites check passed${NC}"
    echo ""
}

# Function to run Dagger commands with error handling
run_dagger() {
    local operation="$1"
    local command="$2"
    
    echo -e "${BLUE}Running: $operation${NC}"
    echo "Command: $command"
    echo ""
    
    if eval "$command"; then
        echo -e "${GREEN}✅ $operation completed successfully${NC}"
        echo ""
    else
        echo -e "${RED}❌ $operation failed${NC}"
        exit 1
    fi
}

# Validate Terraform configuration
validate_terraform() {
    run_dagger "Terraform Validation" \
        "dagger call terraform-validate --source=$TERRAFORM_SOURCE"
}

# Format Terraform files
format_terraform() {
    run_dagger "Terraform Format" \
        "dagger call terraform-format --source=$TERRAFORM_SOURCE"
}

# Run security scan
security_scan() {
    run_dagger "Security Scan" \
        "dagger call security-scan --source=$TERRAFORM_SOURCE"
}

# Plan infrastructure
plan_infrastructure() {
    run_dagger "Terraform Plan ($ENVIRONMENT)" \
        "dagger call terraform-plan --source=$TERRAFORM_SOURCE --env=$ENVIRONMENT --gcp-credentials=file:$GCP_CREDENTIALS_PATH"
}

# Get cost estimate
cost_estimate() {
    run_dagger "Cost Estimation ($ENVIRONMENT)" \
        "dagger call cost-estimate --source=$TERRAFORM_SOURCE --env=$ENVIRONMENT --gcp-credentials=file:$GCP_CREDENTIALS_PATH"
}

# Apply infrastructure (with confirmation)
apply_infrastructure() {
    echo -e "${YELLOW}⚠️  This will apply changes to the $ENVIRONMENT environment${NC}"
    echo "Are you sure you want to continue? (yes/no)"
    read -r confirmation
    
    if [ "$confirmation" = "yes" ]; then
        run_dagger "Terraform Apply ($ENVIRONMENT)" \
            "dagger call terraform-apply --source=$TERRAFORM_SOURCE --env=$ENVIRONMENT --gcp-credentials=file:$GCP_CREDENTIALS_PATH --auto-approve=true"
    else
        echo "Operation cancelled"
        exit 0
    fi
}

# Test infrastructure
test_infrastructure() {
    run_dagger "Infrastructure Test ($ENVIRONMENT)" \
        "dagger call infrastructure-test --source=$TERRAFORM_SOURCE --env=$ENVIRONMENT --gcp-credentials=file:$GCP_CREDENTIALS_PATH"
}

# Destroy infrastructure (with confirmation)
destroy_infrastructure() {
    echo -e "${RED}⚠️  WARNING: This will DESTROY all resources in the $ENVIRONMENT environment${NC}"
    echo "This action cannot be undone. Are you absolutely sure? (type 'destroy' to confirm)"
    read -r confirmation
    
    if [ "$confirmation" = "destroy" ]; then
        run_dagger "Terraform Destroy ($ENVIRONMENT)" \
            "dagger call terraform-destroy --source=$TERRAFORM_SOURCE --env=$ENVIRONMENT --gcp-credentials=file:$GCP_CREDENTIALS_PATH --auto-approve=true"
    else
        echo "Operation cancelled"
        exit 0
    fi
}

# Run full pipeline
full_pipeline() {
    local action="${1:-plan}"
    
    echo -e "${BLUE}Running full pipeline with action: $action${NC}"
    
    if [ "$action" = "apply" ] || [ "$action" = "destroy" ]; then
        echo -e "${YELLOW}⚠️  This will perform $action on the $ENVIRONMENT environment${NC}"
        echo "Are you sure you want to continue? (yes/no)"
        read -r confirmation
        
        if [ "$confirmation" != "yes" ]; then
            echo "Operation cancelled"
            exit 0
        fi
    fi
    
    run_dagger "Full Pipeline ($ENVIRONMENT - $action)" \
        "dagger call full-pipeline --source=$TERRAFORM_SOURCE --env=$ENVIRONMENT --gcp-credentials=file:$GCP_CREDENTIALS_PATH --deploy-action=$action"
}

# Help function
show_help() {
    echo "ModernBlog Terraform Dagger Pipeline - Local Usage"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Environment Variables:"
    echo "  ENVIRONMENT                  Target environment (dev, staging, prod) [default: dev]"
    echo "  GOOGLE_APPLICATION_CREDENTIALS Path to GCP service account JSON file"
    echo ""
    echo "Commands:"
    echo "  validate      Validate Terraform configuration"
    echo "  format        Format Terraform files"
    echo "  security      Run security scan"
    echo "  plan          Create execution plan"
    echo "  cost          Get cost estimate"
    echo "  apply         Apply infrastructure changes"
    echo "  test          Test infrastructure after deployment"
    echo "  destroy       Destroy infrastructure"
    echo "  pipeline      Run full pipeline (plan only)"
    echo "  pipeline-apply Run full pipeline with apply"
    echo "  pipeline-destroy Run full pipeline with destroy"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  ENVIRONMENT=dev $0 validate"
    echo "  ENVIRONMENT=staging $0 plan"
    echo "  ENVIRONMENT=prod $0 pipeline-apply"
}

# Main execution
main() {
    case "${1:-help}" in
        "validate")
            check_prerequisites
            validate_terraform
            ;;
        "format")
            check_prerequisites
            format_terraform
            ;;
        "security")
            check_prerequisites
            security_scan
            ;;
        "plan")
            check_prerequisites
            plan_infrastructure
            ;;
        "cost")
            check_prerequisites
            cost_estimate
            ;;
        "apply")
            check_prerequisites
            apply_infrastructure
            ;;
        "test")
            check_prerequisites
            test_infrastructure
            ;;
        "destroy")
            check_prerequisites
            destroy_infrastructure
            ;;
        "pipeline")
            check_prerequisites
            full_pipeline "plan"
            ;;
        "pipeline-apply")
            check_prerequisites
            full_pipeline "apply"
            ;;
        "pipeline-destroy")
            check_prerequisites
            full_pipeline "destroy"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"