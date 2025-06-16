# Staging environment configuration

terraform {
  backend "gcs" {
    # Backend configuration should be provided via backend config file
    # Example: terraform init -backend-config=backend-staging.hcl
  }
}

module "modernblog" {
  source = "../../"

  # Project configuration
  project_id  = var.project_id
  region      = var.region
  environment = "staging"
  team_name   = var.team_name

  # Network configuration - medium ranges for staging
  cidr_ranges = {
    primary_subnet = "10.1.0.0/22" # 1024 IPs
    pods_range     = "10.1.4.0/22" # 1024 IPs for pods
    services_range = "10.1.8.0/22" # 1024 IPs for services
  }

  # GKE configuration - production-like but smaller
  gke_cluster_config = {
    min_node_count     = 2
    max_node_count     = 4
    machine_type       = "e2-standard-2" # 2 vCPU, 8GB RAM
    disk_size_gb       = 100
    disk_type          = "pd-standard"
    enable_autopilot   = false
    release_channel    = "REGULAR"
    k8s_version_prefix = "1.28"
  }

  # Database configuration - production-like
  database_config = {
    database_version       = "POSTGRES_15"
    tier                   = "db-g1-small" # 1 vCPU, 1.7GB RAM
    disk_size              = 25
    disk_type              = "PD_SSD"
    availability_type      = "ZONAL"
    backup_enabled         = true
    backup_start_time      = "03:00"
    point_in_time_recovery = true
    high_availability      = false
  }

  # Storage configuration
  storage_config = {
    storage_class      = "STANDARD"
    versioning_enabled = true
    lifecycle_rules = [
      {
        age    = 30
        action = "SetStorageClass:NEARLINE"
      },
      {
        age    = 90
        action = "SetStorageClass:COLDLINE"
      }
    ]
    cors_origins = ["https://staging.modernblog.example.com"]
  }

  # Pub/Sub configuration
  pubsub_topics = [
    {
      name                       = "user-notifications"
      message_retention_duration = "259200s" # 3 days
      message_ordering           = false
    },
    {
      name                       = "content-updates"
      message_retention_duration = "259200s"
      message_ordering           = true
    },
    {
      name                       = "analytics-events"
      message_retention_duration = "86400s" # 1 day
      message_ordering           = false
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
      cpu_utilization    = 80
      memory_utilization = 85
      disk_utilization   = 90
      error_rate         = 5
    }
  }
}