# AI Integration with Dagger and Claude Code

This document explains how to integrate Claude Code AI agent into your Dagger CI/CD pipeline.

## Overview

The Dagger module includes AI-powered functions that leverage Claude Code for:
- Code quality analysis
- Security vulnerability detection
- Performance optimization suggestions
- Intelligent error analysis
- Documentation generation

## AI Functions

### 1. AICodeReview()
Analyzes code changes and provides comprehensive feedback:

```go
// Usage in Dagger
result, err := pipeline.AICodeReview(ctx, source, prNumber)
```

**Features:**
- Code quality scoring (0-10)
- Security vulnerability detection
- Performance impact analysis
- Improvement suggestions with file/line references
- Maintainability assessment

### 2. AIOptimization()
Provides optimization recommendations for builds and containers:

```go
// Usage in Dagger
result, err := pipeline.AIOptimization(ctx, source, binaryPath)
```

**Features:**
- Binary size optimization
- Container image optimization
- Build time improvements
- Memory usage analysis
- Deployment optimization

## GitHub Actions Integration

The workflow automatically triggers AI analysis at key points:

### Code Review Stage
```yaml
- name: AI Code Review with Claude
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  run: |
    dagger call ai-code-review --source ../.. --pr-number "$PR_NUMBER"
```

### Build Optimization Stage
```yaml
- name: AI Optimization Analysis
  run: |
    dagger call ai-optimization --source ../.. --binary-path "/app/backend/app"
```

### Failure Analysis
The workflow includes intelligent failure analysis that provides context-aware suggestions for fixing issues.

## Setup Requirements

### 1. Anthropic API Key
Add your Claude API key to GitHub Secrets:
```bash
# In GitHub repository settings > Secrets and variables > Actions
ANTHROPIC_API_KEY=sk-ant-...
```

### 2. Claude Code CLI
The Dagger containers automatically install the Claude Code CLI:
```dockerfile
RUN npm install -g @anthropic/claude-cli
```

### 3. Environment Variables
Configure these in your workflow:
```yaml
env:
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  CLAUDE_MODEL: claude-3-sonnet-20240229
```

## Local Development

### Running AI Analysis Locally
```bash
# Navigate to Dagger module
cd ci/dagger

# Run AI code review
dagger call ai-code-review --source ../.. --pr-number ""

# Run optimization analysis
dagger call ai-optimization --source ../.. --binary-path "./backend/app"

# Run full pipeline with AI
dagger call full-backend-pipeline --source ../.. --options '{"pr_number":"","tag":"local:latest","deploy":"false"}'
```

### Testing AI Integration
```bash
# Test individual AI functions
dagger call ai-code-review --source ../.. --pr-number "123"
dagger call ai-optimization --source ../.. --binary-path "/tmp/app"

# Verify AI responses
dagger call ai-code-review --source ../.. | jq '.suggestions'
```

## AI Response Format

### Code Review Response
```json
{
  "suggestions": [
    {
      "type": "improvement|bug|security|performance",
      "severity": "high|medium|low",
      "file": "backend/main.go",
      "line": 42,
      "description": "Error handling could be improved",
      "suggestion": "Consider wrapping errors with additional context"
    }
  ],
  "code_quality": {
    "score": 8.5,
    "maintainability": "Good",
    "complexity": 12,
    "test_coverage": 75.5
  },
  "security_issues": [],
  "performance": {
    "build_time": "30s",
    "image_size": "45MB",
    "startup_time": "2s",
    "recommendations": [
      "Consider using multi-stage builds",
      "Enable compiler optimizations"
    ]
  }
}
```

### Optimization Response
```json
{
  "suggestions": [
    {
      "type": "performance",
      "severity": "medium",
      "description": "Binary size can be reduced",
      "suggestion": "Use UPX compression for 30% size reduction"
    }
  ],
  "performance": {
    "image_size": "45MB",
    "recommendations": [
      "Enable CGO_ENABLED=0 for static binary",
      "Use distroless base images",
      "Remove debug symbols with -ldflags '-s -w'"
    ]
  }
}
```

## Customization

### Custom AI Prompts
Modify the AI prompts in `ci/dagger/main.go`:

```go
prompt := fmt.Sprintf(`Analyze the following code changes and provide:
1. Custom analysis criteria
2. Project-specific best practices
3. Domain-specific security checks

Code diff:
%s`, diffOutput)
```

### Integration with Other Tools
The AI functions can be extended to integrate with:
- SonarQube for code quality
- Snyk for security scanning
- Prometheus for performance monitoring
- Custom linting rules

## Best Practices

### 1. AI Review Gates
Use AI analysis as quality gates:
```yaml
- name: AI Quality Gate
  run: |
    score=$(dagger call ai-code-review --source ../.. | jq '.code_quality.score')
    if (( $(echo "$score < 7.0" | bc -l) )); then
      echo "Code quality below threshold"
      exit 1
    fi
```

### 2. Progressive AI Enhancement
Start with basic AI integration and gradually add more sophisticated analysis:
- Phase 1: Basic code review
- Phase 2: Security and performance analysis
- Phase 3: Architecture recommendations
- Phase 4: Automated refactoring suggestions

### 3. Human-AI Collaboration
- Use AI for initial analysis
- Require human review for critical changes
- Combine AI insights with domain expertise
- Iterate on AI prompts based on team feedback

## Troubleshooting

### Common Issues

1. **API Rate Limits**
   - Implement exponential backoff
   - Cache AI responses for similar code changes
   - Use different models for different analysis types

2. **Large Diffs**
   - Split large changes into smaller chunks
   - Focus AI analysis on critical files
   - Use file-level analysis for better performance

3. **Context Understanding**
   - Provide more context in prompts
   - Include relevant documentation
   - Use project-specific terminology

### Debugging AI Responses
```bash
# Enable verbose logging
export DAGGER_LOG_LEVEL=debug

# Test AI functions individually
dagger call ai-code-review --source ../.. --pr-number "" | jq '.'

# Check API connectivity
curl -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
     -H "Content-Type: application/json" \
     https://api.anthropic.com/v1/messages
```

## Future Enhancements

- [ ] Automated code refactoring based on AI suggestions
- [ ] Integration with IDE extensions
- [ ] Custom model fine-tuning for project-specific patterns
- [ ] Multi-language support beyond Go
- [ ] Automated documentation generation
- [ ] Performance regression detection
- [ ] Intelligent test generation