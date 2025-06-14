# Development environment configuration

terraform {
  backend "gcs" {
    # Backend configuration should be provided via backend config file
    # Example: terraform init -backend-config=backend-dev.hcl
  }
}

module "modernblog" {
  source = "../../"
  
  # Project configuration
  project_id  = var.project_id
  region      = var.region
  environment = "dev"
  team_name   = var.team_name
  
  # Network configuration - smaller ranges for dev
  cidr_ranges = {
    primary_subnet = "10.0.0.0/24"    # 256 IPs
    pods_range     = "10.0.1.0/24"    # 256 IPs for pods
    services_range = "10.0.2.0/24"    # 256 IPs for services
  }
  
  # GKE configuration - minimal for dev
  gke_cluster_config = {
    min_node_count     = 1
    max_node_count     = 2
    machine_type       = "e2-medium"  # 2 vCPU, 4GB RAM
    disk_size_gb       = 50
    disk_type          = "pd-standard"
    enable_autopilot   = false
    release_channel    = "RAPID"      # Latest features for dev
    k8s_version_prefix = "1.28"
  }
  
  # Database configuration - minimal for dev
  database_config = {
    database_version       = "POSTGRES_15"
    tier                   = "db-f1-micro"  # 1 vCPU, 0.6GB RAM
    disk_size              = 10
    disk_type              = "PD_HDD"
    availability_type      = "ZONAL"
    backup_enabled         = true
    backup_start_time      = "03:00"
    point_in_time_recovery = false
    high_availability      = false
  }
  
  # Storage configuration
  storage_config = {
    storage_class      = "STANDARD"
    versioning_enabled = false  # No versioning in dev
    lifecycle_rules = [
      {
        age    = 7   # Move to nearline after 7 days
        action = "SetStorageClass:NEARLINE"
      },
      {
        age    = 30  # Delete after 30 days
        action = "Delete"
      }
    ]
    cors_origins = ["http://localhost:3000", "http://localhost:5173"]
  }
  
  # Pub/Sub configuration
  pubsub_topics = [
    {
      name                       = "user-notifications"
      message_retention_duration = "86400s"  # 1 day
      message_ordering          = false
    },
    {
      name                       = "content-updates"
      message_retention_duration = "86400s"
      message_ordering          = false
    }
  ]
  
  # Monitoring configuration
  monitoring_config = {
    notification_channels = [
      {
        type  = "email"
        email = var.alert_email
      }
    ]
    alert_thresholds = {
      cpu_utilization    = 90  # Higher thresholds for dev
      memory_utilization = 90
      disk_utilization   = 95
      error_rate         = 10
    }
  }
}