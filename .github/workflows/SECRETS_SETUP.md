# GitHub Actions Secrets Setup

## Required Secrets

### GCP_SERVICE_ACCOUNT_KEY

This secret contains the Google Cloud Platform service account key in JSON format.

**Setup Instructions:**

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `GCP_SERVICE_ACCOUNT_KEY`
5. Value: Paste the entire contents of your GCP service account JSON key file

**Service Account Requirements:**

The service account should have the following permissions:
- Compute Admin
- Cloud SQL Admin
- Service Account User
- Storage Admin
- Cloud Run Admin
- Secret Manager Admin
- Project IAM Admin (if managing IAM bindings)

**Creating a Service Account Key:**

```bash
# Create service account
gcloud iam service-accounts create modernblog-terraform \
  --display-name="ModernBlog Terraform Service Account" \
  --project=taskmate-461721

# Grant necessary roles
gcloud projects add-iam-policy-binding taskmate-461721 \
  --member="serviceAccount:modernblog-terraform@taskmate-461721.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# Add other required roles...

# Create and download key
gcloud iam service-accounts keys create ~/modernblog-terraform-key.json \
  --iam-account=modernblog-terraform@taskmate-461721.iam.gserviceaccount.com
```

**Security Notes:**
- Never commit the service account key to your repository
- Rotate keys regularly
- Use least-privilege principle for permissions
- Consider using Workload Identity Federation for production environments