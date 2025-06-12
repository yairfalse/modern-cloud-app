#!/bin/bash

# Dagger Backend Pipeline - Local Usage Script
# This script demonstrates how to run the AI-enhanced CI/CD pipeline locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_TAG="backend:local-$(date +%s)"
NAMESPACE="backend-dev"
SOURCE_DIR="../.."

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v dagger &> /dev/null; then
        log_error "Dagger CLI not found. Please install: https://docs.dagger.io/cli"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found. Please install Docker."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq not found. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install jq
        else
            sudo apt-get update && sudo apt-get install -y jq
        fi
    fi
    
    log_success "Prerequisites check completed"
}

# Run linting
run_lint() {
    log_info "Running backend linting..."
    
    if dagger call lint-backend --source "$SOURCE_DIR" > lint-output.txt 2>&1; then
        log_success "Linting passed"
        cat lint-output.txt
    else
        log_error "Linting failed"
        cat lint-output.txt
        return 1
    fi
}

# Run tests
run_tests() {
    log_info "Running backend tests with coverage..."
    
    if result=$(dagger call test-backend --source "$SOURCE_DIR" 2>&1); then
        echo "$result" | tee test-output.txt
        
        # Extract coverage
        coverage=$(echo "$result" | jq -r '.coverage // 0' 2>/dev/null || echo "0")
        log_success "Tests passed with ${coverage}% coverage"
        
        if (( $(echo "$coverage < 70" | bc -l) )); then
            log_warning "Test coverage is below 70%"
        fi
    else
        log_error "Tests failed"
        echo "$result"
        return 1
    fi
}

# Run AI code review
run_ai_review() {
    log_info "Running AI code review..."
    
    if ! command -v claude &> /dev/null && [ -z "$ANTHROPIC_API_KEY" ]; then
        log_warning "Claude CLI or ANTHROPIC_API_KEY not found. Skipping AI review."
        return 0
    fi
    
    if result=$(dagger call ai-code-review --source "$SOURCE_DIR" --pr-number "" 2>/dev/null); then
        echo "$result" | jq '.' > ai-review.json
        
        # Display AI suggestions
        suggestions=$(echo "$result" | jq -r '.suggestions[]? | "- \(.type) (\(.severity)): \(.description)"' 2>/dev/null || echo "No suggestions")
        quality_score=$(echo "$result" | jq -r '.code_quality.score // "N/A"' 2>/dev/null)
        
        log_success "AI Code Review completed"
        echo "Quality Score: $quality_score/10"
        echo "Suggestions:"
        echo "$suggestions"
    else
        log_warning "AI code review failed or skipped"
    fi
}

# Build backend
build_backend() {
    log_info "Building backend binary..."
    
    if dagger call build-backend --source "$SOURCE_DIR" > build-output.txt 2>&1; then
        log_success "Backend build completed"
        cat build-output.txt
    else
        log_error "Backend build failed"
        cat build-output.txt
        return 1
    fi
}

# Build container
build_container() {
    log_info "Building container image: $BACKEND_TAG"
    
    if dagger call build-container --source "$SOURCE_DIR" --tag "$BACKEND_TAG" > container-output.txt 2>&1; then
        log_success "Container build completed"
        cat container-output.txt
        
        # Verify image exists
        if docker image inspect "$BACKEND_TAG" >/dev/null 2>&1; then
            size=$(docker image inspect "$BACKEND_TAG" --format='{{.Size}}' | numfmt --to=iec)
            log_success "Container image size: $size"
        fi
    else
        log_error "Container build failed"
        cat container-output.txt
        return 1
    fi
}

# Run AI optimization
run_ai_optimization() {
    log_info "Running AI optimization analysis..."
    
    if result=$(dagger call ai-optimization --source "$SOURCE_DIR" --binary-path "/app/backend/app" 2>/dev/null); then
        echo "$result" | jq '.' > ai-optimization.json
        
        # Display optimization recommendations
        recommendations=$(echo "$result" | jq -r '.performance.recommendations[]? | "- \(.)"' 2>/dev/null || echo "No recommendations")
        
        log_success "AI Optimization analysis completed"
        echo "Recommendations:"
        echo "$recommendations"
    else
        log_warning "AI optimization analysis failed or skipped"
    fi
}

# Test container
test_container() {
    log_info "Testing container functionality..."
    
    if result=$(dagger call test-container --container-tag "$BACKEND_TAG" 2>&1); then
        echo "$result" | tee container-test-output.txt
        
        # Parse test results
        total_tests=$(echo "$result" | jq -r '.total_tests // 0' 2>/dev/null || echo "0")
        passed_tests=$(echo "$result" | jq -r '.passed_tests // 0' 2>/dev/null || echo "0")
        failed_tests=$(echo "$result" | jq -r '.failed_tests // 0' 2>/dev/null || echo "0")
        
        log_success "Container tests: $passed_tests/$total_tests passed"
        
        if [ "$failed_tests" -gt 0 ]; then
            log_warning "Some container tests failed"
            return 1
        fi
    else
        log_error "Container tests failed"
        echo "$result"
        return 1
    fi
}

# Deploy locally (requires Kind or similar)
deploy_local() {
    log_info "Deploying to local Kubernetes..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl not found. Skipping local deployment."
        return 0
    fi
    
    # Check if cluster is available
    if ! kubectl cluster-info &> /dev/null; then
        log_warning "No Kubernetes cluster available. Skipping deployment."
        return 0
    fi
    
    if result=$(dagger call deploy-local --source "$SOURCE_DIR" --namespace "$NAMESPACE" 2>&1); then
        echo "$result" | tee deploy-output.txt
        log_success "Local deployment completed to namespace: $NAMESPACE"
        
        # Show deployment status
        kubectl get pods -n "$NAMESPACE" 2>/dev/null || true
    else
        log_warning "Local deployment failed or skipped"
        echo "$result"
    fi
}

# Run integration tests
run_integration_tests() {
    log_info "Running integration tests..."
    
    if ! kubectl cluster-info &> /dev/null; then
        log_warning "No Kubernetes cluster available. Skipping integration tests."
        return 0
    fi
    
    if result=$(dagger call integration-test --namespace "$NAMESPACE" 2>&1); then
        echo "$result" | tee integration-test-output.txt
        
        # Parse results
        total_tests=$(echo "$result" | jq -r '.total_tests // 0' 2>/dev/null || echo "0")
        passed_tests=$(echo "$result" | jq -r '.passed_tests // 0' 2>/dev/null || echo "0")
        failed_tests=$(echo "$result" | jq -r '.failed_tests // 0' 2>/dev/null || echo "0")
        coverage=$(echo "$result" | jq -r '.coverage // 0' 2>/dev/null || echo "0")
        
        log_success "Integration tests: $passed_tests/$total_tests passed (${coverage}% coverage)"
        
        if [ "$failed_tests" -gt 0 ]; then
            log_warning "Some integration tests failed"
        fi
    else
        log_warning "Integration tests failed or skipped"
        echo "$result"
    fi
}

# Run full pipeline
run_full_pipeline() {
    log_info "Running full AI-enhanced backend pipeline..."
    
    options=$(jq -n \
        --arg tag "$BACKEND_TAG" \
        --arg namespace "$NAMESPACE" \
        --arg deploy "true" \
        '{tag: $tag, namespace: $namespace, deploy: $deploy}')
    
    if result=$(dagger call full-backend-pipeline --source "$SOURCE_DIR" --options "$options" 2>&1); then
        echo "$result" | jq '.' > full-pipeline-results.json 2>/dev/null || echo "$result" > full-pipeline-results.txt
        log_success "Full pipeline completed successfully"
        
        # Display summary
        echo ""
        echo "🎯 Pipeline Summary:"
        echo "==================="
        if [ -f full-pipeline-results.json ]; then
            jq -r 'to_entries[] | "- \(.key): \(.value.success // .value.passed_tests // "completed")"' full-pipeline-results.json 2>/dev/null || cat full-pipeline-results.txt
        else
            echo "Results saved to full-pipeline-results.txt"
        fi
    else
        log_error "Full pipeline failed"
        echo "$result"
        return 1
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up resources..."
    
    # Remove temporary files
    rm -f lint-output.txt test-output.txt build-output.txt container-output.txt
    rm -f container-test-output.txt deploy-output.txt integration-test-output.txt
    rm -f ai-review.json ai-optimization.json full-pipeline-results.json full-pipeline-results.txt
    
    # Remove local container image
    if docker image inspect "$BACKEND_TAG" >/dev/null 2>&1; then
        docker rmi "$BACKEND_TAG" >/dev/null 2>&1 || true
        log_info "Removed container image: $BACKEND_TAG"
    fi
    
    # Optional: cleanup Kubernetes namespace
    if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        read -p "Remove Kubernetes namespace $NAMESPACE? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
            log_info "Removed namespace: $NAMESPACE"
        fi
    fi
}

# Main function
main() {
    echo "🚀 Dagger Backend Pipeline with AI Integration"
    echo "=============================================="
    echo ""
    
    # Parse command line arguments
    COMMAND=${1:-"full"}
    
    case $COMMAND in
        "check")
            check_prerequisites
            ;;
        "lint")
            check_prerequisites
            run_lint
            ;;
        "test")
            check_prerequisites
            run_tests
            ;;
        "ai-review")
            check_prerequisites
            run_ai_review
            ;;
        "build")
            check_prerequisites
            build_backend
            build_container
            ;;
        "ai-optimize")
            check_prerequisites
            run_ai_optimization
            ;;
        "container-test")
            check_prerequisites
            test_container
            ;;
        "deploy")
            check_prerequisites
            deploy_local
            ;;
        "integration")
            check_prerequisites
            run_integration_tests
            ;;
        "full")
            check_prerequisites
            run_full_pipeline
            ;;
        "individual")
            check_prerequisites
            run_lint
            run_tests
            run_ai_review
            build_backend
            build_container
            run_ai_optimization
            test_container
            deploy_local
            run_integration_tests
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  check          - Check prerequisites"
            echo "  lint           - Run linting only"
            echo "  test           - Run tests only"
            echo "  ai-review      - Run AI code review"
            echo "  build          - Build backend and container"
            echo "  ai-optimize    - Run AI optimization analysis"
            echo "  container-test - Test container functionality"
            echo "  deploy         - Deploy to local Kubernetes"
            echo "  integration    - Run integration tests"
            echo "  full           - Run complete pipeline (default)"
            echo "  individual     - Run all steps individually"
            echo "  cleanup        - Clean up resources"
            echo ""
            echo "Examples:"
            echo "  $0 full        # Run complete pipeline"
            echo "  $0 individual  # Run steps individually"
            echo "  $0 ai-review   # Run only AI analysis"
            echo "  $0 cleanup     # Clean up resources"
            exit 1
            ;;
    esac
    
    # Trap cleanup on exit
    if [ "$COMMAND" != "cleanup" ]; then
        trap cleanup EXIT
    fi
}

# Run main function
main "$@"