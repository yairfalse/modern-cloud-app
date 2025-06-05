# Main Terraform configuration for ModernBlog platform
# This file orchestrates all modules and creates the infrastructure

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  
  # Backend configuration for state management
  # Configure based on environment using backend config files
  backend "gcs" {}
}

# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Local variables for resource naming and tagging
locals {
  environment = var.environment
  app_name    = "modernblog"
  
  # Common labels applied to all resources
  common_labels = {
    app         = local.app_name
    environment = local.environment
    managed_by  = "terraform"
    team        = var.team_name
  }
  
  # Resource name prefix
  name_prefix = "${local.app_name}-${local.environment}"
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
  ])
  
  service = each.key
  
  disable_on_destroy = false
}

# VPC Network module
module "networking" {
  source = "./modules/networking"
  
  project_id    = var.project_id
  region        = var.region
  environment   = local.environment
  name_prefix   = local.name_prefix
  common_labels = local.common_labels
  
  # Network configuration
  cidr_ranges = var.cidr_ranges
  
  depends_on = [google_project_service.apis]
}

# IAM module for service accounts and roles
module "iam" {
  source = "./modules/iam"
  
  project_id    = var.project_id
  environment   = local.environment
  name_prefix   = local.name_prefix
  common_labels = local.common_labels
  
  depends_on = [google_project_service.apis]
}

# GKE cluster module
module "gke" {
  source = "./modules/gke"
  
  project_id    = var.project_id
  region        = var.region
  environment   = local.environment
  name_prefix   = local.name_prefix
  common_labels = local.common_labels
  
  # Network configuration
  network           = module.networking.network_name
  subnetwork        = module.networking.subnet_name
  pods_range_name   = module.networking.pods_range_name
  services_range_name = module.networking.services_range_name
  
  # Cluster configuration
  cluster_config = var.gke_cluster_config
  
  # Service account
  service_account_email = module.iam.gke_service_account_email
  
  depends_on = [module.networking, module.iam]
}

# Cloud SQL PostgreSQL module
module "cloudsql" {
  source = "./modules/cloudsql"
  
  project_id    = var.project_id
  region        = var.region
  environment   = local.environment
  name_prefix   = local.name_prefix
  common_labels = local.common_labels
  
  # Network configuration
  network_id = module.networking.network_id
  
  # Database configuration
  database_config = var.database_config
  
  depends_on = [module.networking]
}

# Cloud Storage module
module "storage" {
  source = "./modules/storage"
  
  project_id    = var.project_id
  region        = var.region
  environment   = local.environment
  name_prefix   = local.name_prefix
  common_labels = local.common_labels
  
  # Storage configuration
  storage_config = var.storage_config
  
  # Service account for storage access
  storage_admin_email = module.iam.storage_admin_email
  
  depends_on = [module.iam]
}

# Pub/Sub module
module "pubsub" {
  source = "./modules/pubsub"
  
  project_id    = var.project_id
  environment   = local.environment
  name_prefix   = local.name_prefix
  common_labels = local.common_labels
  
  # Topic configuration
  topics = var.pubsub_topics
  
  # Service account for Pub/Sub
  pubsub_service_account_email = module.iam.pubsub_service_account_email
  
  depends_on = [module.iam]
}

# Monitoring module
module "monitoring" {
  source = "./modules/monitoring"
  
  project_id    = var.project_id
  environment   = local.environment
  name_prefix   = local.name_prefix
  common_labels = local.common_labels
  
  # Resources to monitor
  gke_cluster_name = module.gke.cluster_name
  database_instance_name = module.cloudsql.instance_name
  
  # Notification configuration
  notification_config = var.monitoring_config
  
  depends_on = [module.gke, module.cloudsql]
}