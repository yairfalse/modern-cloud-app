# ModernBlog Terraform Infrastructure

This directory contains the Terraform configuration for deploying the ModernBlog platform on Google Cloud Platform (GCP).

## Architecture Overview

The infrastructure includes:

- **Networking**: VPC with subnets for GKE, Cloud NAT, and firewall rules
- **GKE Cluster**: Kubernetes cluster with Cilium CNI (Dataplane V2) enabled
- **Cloud SQL**: PostgreSQL database with high availability options
- **Cloud Storage**: Buckets for media files, backups, and static assets
- **IAM**: Service accounts and roles for secure access control
- **Pub/Sub**: Topics and subscriptions for event-driven architecture
- **Monitoring**: Dashboards, alerts, and logging configuration

## Directory Structure

```
terraform/
├── main.tf                 # Root module configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── terraform.tfvars.example # Example variables file
├── modules/                # Reusable Terraform modules
│   ├── networking/         # VPC and network configuration
│   ├── gke/                # GKE cluster configuration
│   ├── cloudsql/           # Cloud SQL database
│   ├── storage/            # Cloud Storage buckets
│   ├── iam/                # IAM service accounts and roles
│   ├── pubsub/             # Pub/Sub topics and subscriptions
│   └── monitoring/         # Monitoring and alerting
└── environments/           # Environment-specific configurations
    ├── dev/                # Development environment
    ├── staging/            # Staging environment
    └── prod/               # Production environment
```

## Prerequisites

1. **GCP Project**: Create a GCP project for each environment
2. **Terraform**: Install Terraform >= 1.5.0
3. **gcloud CLI**: Install and configure the Google Cloud SDK
4. **APIs**: Enable required GCP APIs (done automatically by Terraform)
5. **State Bucket**: Create a GCS bucket for Terraform state storage

## Getting Started

### 1. Set up authentication

```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### 2. Create state buckets

Create GCS buckets for storing Terraform state:

```bash
# For each environment
gsutil mb -p YOUR_PROJECT_ID -c STANDARD -l us-central1 gs://YOUR_TERRAFORM_STATE_BUCKET/
gsutil versioning set on gs://YOUR_TERRAFORM_STATE_BUCKET/
```

### 3. Configure backend

Copy the backend configuration example and update with your values:

```bash
cd environments/dev
cp backend-dev.hcl.example backend-dev.hcl
# Edit backend-dev.hcl with your bucket name
```

### 4. Configure variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project details
```

### 5. Initialize and deploy

```bash
# Initialize Terraform with backend configuration
terraform init -backend-config=backend-dev.hcl

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## Environment-Specific Deployment

Each environment has its own configuration optimized for its use case:

### Development Environment

```bash
cd environments/dev
terraform init -backend-config=backend-dev.hcl
terraform apply
```

**Features:**
- Minimal resources for cost optimization
- Single node GKE cluster
- Small database instance
- Relaxed monitoring thresholds

### Staging Environment

```bash
cd environments/staging
terraform init -backend-config=backend-staging.hcl
terraform apply
```

**Features:**
- Production-like configuration
- Multi-node GKE cluster
- Medium-sized database
- Production monitoring setup

### Production Environment

```bash
cd environments/prod
terraform init -backend-config=backend-prod.hcl
terraform apply
```

**Features:**
- High availability configuration
- Auto-scaling GKE cluster
- Regional database with replicas
- Comprehensive monitoring and alerting

## Module Usage

Each module can be used independently:

```hcl
module "networking" {
  source = "./modules/networking"
  
  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  name_prefix   = local.name_prefix
  common_labels = local.common_labels
  cidr_ranges   = var.cidr_ranges
}
```

## Important Configurations

### GKE with Cilium

The GKE cluster is configured with Dataplane V2 (Cilium) for advanced networking:

```hcl
datapath_provider = "ADVANCED_DATAPATH"
```

### Workload Identity

Workload Identity is enabled for secure pod-to-GCP service authentication:

```hcl
workload_identity_config {
  workload_pool = "${var.project_id}.svc.id.goog"
}
```

### Private Networking

All resources use private IPs with Cloud NAT for outbound connectivity:

```hcl
private_cluster_config {
  enable_private_nodes    = true
  enable_private_endpoint = false
}
```

## Security Best Practices

1. **Service Accounts**: Each component has its own service account with minimal permissions
2. **Private IPs**: All resources use private IPs within the VPC
3. **Encryption**: All data is encrypted at rest
4. **Secrets Management**: Sensitive data stored in Secret Manager
5. **Network Policies**: Firewall rules restrict traffic between components

## Cost Optimization

1. **Environment-specific sizing**: Dev uses minimal resources
2. **Preemptible nodes**: Used in non-production environments
3. **Lifecycle policies**: Automatic archival of old data
4. **Regional resources**: Use zonal resources where HA is not required

## Monitoring and Alerting

The monitoring module creates:

- Custom dashboards for cluster and database metrics
- Alert policies for CPU, memory, and error rates
- Log sinks for long-term storage
- Uptime checks for application health

## Troubleshooting

### Common Issues

1. **API not enabled**: The configuration automatically enables required APIs
2. **Insufficient quota**: Check and increase quotas in the GCP console
3. **Permission denied**: Ensure your account has the required IAM roles
4. **State lock**: Use `terraform force-unlock` if state is locked

### Useful Commands

```bash
# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# Import existing resources
terraform import module.gke.google_container_cluster.primary projects/PROJECT_ID/locations/REGION/clusters/CLUSTER_NAME

# Destroy specific resources
terraform destroy -target=module.monitoring
```

## GitOps Integration

This Terraform configuration is designed for GitOps workflows:

1. **State Management**: Remote state in GCS with locking
2. **Environment Separation**: Separate directories for each environment
3. **Module Versioning**: Modules can be versioned and published
4. **CI/CD Ready**: Can be integrated with Cloud Build or other CI/CD tools

## Contributing

1. Make changes in a feature branch
2. Test in the dev environment first
3. Run `terraform fmt` and `terraform validate`
4. Create a pull request with the plan output
5. Apply changes after approval

## License

This configuration is part of the ModernBlog platform and follows the same license terms.