# GitHub Actions Setup Guide

This guide walks you through setting up the Terraform Dagger pipeline in GitHub Actions.

## Prerequisites

1. **GCP Service Account**: Create a service account with the necessary permissions
2. **GitHub Repository**: Access to repository settings for secrets and environments

## Step 1: Create GCP Service Account

1. **Create the service account**:
   ```bash
   gcloud iam service-accounts create terraform-github \
     --description="Service account for GitHub Actions Terraform deployments" \
     --display-name="Terraform GitHub Actions"
   ```

2. **Grant necessary permissions**:
   ```bash
   # Project Editor (or more specific roles based on your needs)
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:terraform-github@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/editor"
   
   # Storage Admin for Terraform state
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:terraform-github@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/storage.admin"
   
   # Compute Admin for GKE and VM management
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:terraform-github@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/compute.admin"
   
   # Kubernetes Engine Admin
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:terraform-github@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/container.admin"
   
   # Cloud SQL Admin
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:terraform-github@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/cloudsql.admin"
   
   # Pub/Sub Admin
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:terraform-github@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/pubsub.admin"
   
   # Monitoring Admin
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:terraform-github@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/monitoring.admin"
   ```

3. **Create and download service account key**:
   ```bash
   gcloud iam service-accounts keys create terraform-github-key.json \
     --iam-account=terraform-github@YOUR_PROJECT_ID.iam.gserviceaccount.com
   ```

## Step 2: Configure GitHub Secrets

1. **Navigate to your repository settings**:
   - Go to `Settings` > `Secrets and variables` > `Actions`

2. **Add repository secrets**:
   - `GCP_SA_KEY`: Contents of the `terraform-github-key.json` file
   - `GCP_PROJECT_ID`: Your Google Cloud project ID (optional, can be set in Terraform variables)

## Step 3: Set Up GitHub Environments

1. **Navigate to environments**:
   - Go to `Settings` > `Environments`

2. **Create environments**:
   
   ### Development Environment
   - Name: `development`
   - Protection rules: None (auto-deploy from develop branch)
   
   ### Staging Environment
   - Name: `staging`
   - Protection rules: None (auto-deploy from main branch)
   - Environment secrets: Can override `GCP_SA_KEY` with staging-specific credentials if needed
   
   ### Production Environment
   - Name: `production`
   - Protection rules:
     - ✅ Required reviewers: Add team members who can approve production deployments
     - ✅ Wait timer: 5 minutes (optional)
     - ✅ Deployment branches: Only main branch
   - Environment secrets: Production-specific `GCP_SA_KEY` if different from repository secret

## Step 4: Configure Branch Protection

1. **Protect main branch**:
   - Go to `Settings` > `Branches`
   - Add rule for `main`:
     - ✅ Require pull request reviews before merging
     - ✅ Require status checks to pass before merging
     - ✅ Require branches to be up to date before merging
     - ✅ Include administrators

2. **Protect develop branch**:
   - Add rule for `develop`:
     - ✅ Require status checks to pass before merging
     - Status checks: `Validate Terraform Configuration`, `Security Scan`

## Step 5: Test the Pipeline

1. **Create a test branch**:
   ```bash
   git checkout -b test/github-actions-setup
   ```

2. **Make a small change to Terraform**:
   ```bash
   # Add a comment or variable to test the pipeline
   echo "# Test comment for GitHub Actions" >> terraform/variables.tf
   git add terraform/variables.tf
   git commit -m "test: add comment to test GitHub Actions pipeline"
   ```

3. **Push and create PR**:
   ```bash
   git push origin test/github-actions-setup
   ```
   - Create a pull request to the `develop` branch
   - Watch the pipeline run validation and security scans

4. **Merge to develop**:
   - Merge the PR to trigger development deployment

## Workflow Triggers

The pipeline responds to these events:

### Automatic Triggers
- **Pull Request to main**: Validation, security scan, and planning
- **Push to develop**: Auto-deploy to development environment
- **Push to main**: Auto-deploy to staging environment

### Manual Triggers
- **Workflow Dispatch**: Manual operations on any environment
  - Environment: dev, staging, prod
  - Action: plan, apply, destroy

## Pipeline Stages

### 1. Validation Stage
- Terraform validation
- Format checking
- Security scanning with tfsec

### 2. Planning Stage
- Cost estimation
- Terraform planning for target environments
- Artifact generation (plans, outputs)

### 3. Deployment Stage
- Environment-specific deployment
- Infrastructure testing
- State verification

## Monitoring and Troubleshooting

### View Pipeline Results
1. Go to `Actions` tab in your repository
2. Click on the workflow run
3. Expand job steps to see detailed logs

### Common Issues

1. **Authentication Failures**:
   - Verify `GCP_SA_KEY` secret is correctly set
   - Check service account permissions

2. **Terraform State Locks**:
   - Ensure no concurrent operations
   - Check GCS bucket permissions for state storage

3. **Resource Quotas**:
   - Verify GCP quotas for your project
   - Check regional availability of resources

### Debug Mode
Enable debug logging by adding this to workflow environment variables:
```yaml
env:
  DAGGER_LOG_LEVEL: debug
```

## Security Best Practices

1. **Principle of Least Privilege**: Grant minimum required permissions to service accounts
2. **Environment Separation**: Use different service accounts for different environments
3. **Secret Rotation**: Regularly rotate service account keys
4. **Audit Logs**: Monitor GCP audit logs for service account usage
5. **Branch Protection**: Require reviews for production changes

## Customization

### Environment-Specific Variables
Add environment-specific secrets or variables:
- `GCP_SA_KEY_DEV`
- `GCP_SA_KEY_STAGING`
- `GCP_SA_KEY_PROD`

### Additional Notifications
Add Slack or email notifications by extending the workflow:
```yaml
- name: Notify deployment
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Custom Approval Process
For more complex approval workflows, consider using:
- GitHub Issues for change requests
- External approval systems
- Additional manual gates

## Maintenance

### Regular Tasks
1. **Update Dagger version** in workflows
2. **Review and rotate** service account keys
3. **Update Terraform version** in Dagger container
4. **Monitor cost trends** from pipeline reports
5. **Review security scan results** and update configurations

### Backup and Recovery
1. **Terraform State**: Automatically backed up in GCS
2. **Pipeline Configuration**: Version controlled in repository
3. **Service Account Keys**: Store securely and maintain backups