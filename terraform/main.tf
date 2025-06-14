# ModernBlog Single Cluster + Namespaces Configuration
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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }

  backend "gcs" {
    # Backend configuration provided via backend.hcl
  }
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

# Networking module
module "networking" {
  source = "./modules/networking"

  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
  environment = "single-cluster"

  # Network configuration
  cidr_ranges = {
    primary_subnet = "10.0.0.0/24"
    pods_range     = "10.0.1.0/24"
    services_range = "10.0.2.0/24"
  }
}

# GKE Cluster module
module "gke" {
  source = "./modules/gke"

  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
  environment = "single-cluster"

  # Use networking outputs
  network    = module.networking.network_name
  subnetwork = module.networking.subnet_name

  # Single cluster configuration
  cluster_config = {
    min_node_count     = 1
    max_node_count     = 3
    machine_type       = "e2-medium"
    disk_size_gb       = 50
    disk_type          = "pd-standard"
    enable_autopilot   = false
    release_channel    = "RAPID"
    k8s_version_prefix = "1.28"
  }
}

# Database module
module "cloudsql" {
  source = "./modules/cloudsql"

  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
  environment = "single-cluster"

  network = module.networking.network_name

  database_config = {
    database_version       = "POSTGRES_15"
    tier                   = "db-f1-micro"
    disk_size              = 10
    disk_type              = "PD_HDD"
    availability_type      = "ZONAL"
    backup_enabled         = true
    backup_start_time      = "03:00"
    point_in_time_recovery = false
    high_availability      = false
  }
}

# Storage module
module "storage" {
  source = "./modules/storage"

  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
  environment = "single-cluster"

  storage_config = {
    storage_class      = "STANDARD"
    versioning_enabled = false
    cors_origins       = ["http://localhost:3000", "http://localhost:5173"]
  }
}

# Get cluster credentials for Kubernetes provider
data "google_container_cluster" "primary" {
  name     = module.gke.cluster_name
  location = var.region

  depends_on = [module.gke]
}

data "google_client_config" "default" {}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

# Create Namespaces
resource "kubernetes_namespace" "modernblog_dev" {
  metadata {
    name = "modernblog-dev"
    labels = {
      environment = "dev"
      team        = var.team_name
    }
  }

  depends_on = [module.gke]
}

resource "kubernetes_namespace" "modernblog_prod" {
  metadata {
    name = "modernblog-prod"
    labels = {
      environment = "prod"
      team        = var.team_name
    }
  }

  depends_on = [module.gke]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      purpose = "monitoring"
      team    = var.team_name
    }
  }

  depends_on = [module.gke]
}
