# Production environment configuration

terraform {
  backend "gcs" {
    # Backend configuration should be provided via backend config file
    # Example: terraform init -backend-config=backend-prod.hcl
  }
}

module "modernblog" {
  source = "../../"

  # Project configuration
  project_id  = var.project_id
  region      = var.region
  environment = "prod"
  team_name   = var.team_name

  # Network configuration - production ranges
  cidr_ranges = {
    primary_subnet = "10.2.0.0/20"  # 4096 IPs
    pods_range     = "10.2.16.0/20" # 4096 IPs for pods
    services_range = "10.2.32.0/20" # 4096 IPs for services
  }

  # GKE configuration - production ready
  gke_cluster_config = {
    min_node_count     = 3
    max_node_count     = 10
    machine_type       = "e2-standard-4" # 4 vCPU, 16GB RAM
    disk_size_gb       = 100
    disk_type          = "pd-ssd"
    enable_autopilot   = false
    release_channel    = "STABLE" # Most stable for production
    k8s_version_prefix = "1.28"
  }

  # Database configuration - high availability
  database_config = {
    database_version       = "POSTGRES_15"
    tier                   = "db-n1-standard-2" # 2 vCPU, 7.5GB RAM
    disk_size              = 100
    disk_type              = "PD_SSD"
    availability_type      = "REGIONAL" # High availability
    backup_enabled         = true
    backup_start_time      = "03:00"
    point_in_time_recovery = true
    high_availability      = true
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
      },
      {
        age    = 365
        action = "SetStorageClass:ARCHIVE"
      }
    ]
    cors_origins = ["https://modernblog.example.com", "https://www.modernblog.example.com"]
  }

  # Pub/Sub configuration
  pubsub_topics = [
    {
      name                       = "user-notifications"
      message_retention_duration = "604800s" # 7 days
      message_ordering           = false
    },
    {
      name                       = "content-updates"
      message_retention_duration = "604800s"
      message_ordering           = true
    },
    {
      name                       = "analytics-events"
      message_retention_duration = "259200s" # 3 days
      message_ordering           = false
    }
  ]

  # Monitoring configuration
  monitoring_config = {
    notification_channels = concat(
      [for email in var.alert_emails : {
        type  = "email"
        email = email
      }],
      var.pagerduty_enabled ? [{
        type  = "pagerduty"
        email = var.pagerduty_email
      }] : []
    )
    alert_thresholds = {
      cpu_utilization    = 75
      memory_utilization = 80
      disk_utilization   = 85
      error_rate         = 2
    }
  }
}