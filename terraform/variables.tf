# Input variables for the ModernBlog Terraform configuration

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "The GCP region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "team_name" {
  description = "Team name for resource labeling"
  type        = string
  default     = "platform"
}

# Network configuration
variable "cidr_ranges" {
  description = "CIDR ranges for VPC subnets"
  type = object({
    primary_subnet = string
    pods_range     = string
    services_range = string
  })
  default = {
    primary_subnet = "10.0.0.0/20"
    pods_range     = "10.0.16.0/20"
    services_range = "10.0.32.0/20"
  }
}

# GKE cluster configuration
variable "gke_cluster_config" {
  description = "Configuration for GKE cluster"
  type = object({
    min_node_count     = number
    max_node_count     = number
    machine_type       = string
    disk_size_gb       = number
    disk_type          = string
    enable_autopilot   = bool
    release_channel    = string
    k8s_version_prefix = string
  })
  default = {
    min_node_count     = 1
    max_node_count     = 3
    machine_type       = "e2-standard-4"
    disk_size_gb       = 100
    disk_type          = "pd-standard"
    enable_autopilot   = false
    release_channel    = "REGULAR"
    k8s_version_prefix = "1.28"
  }
}

# Database configuration
variable "database_config" {
  description = "Configuration for Cloud SQL PostgreSQL"
  type = object({
    database_version       = string
    tier                   = string
    disk_size              = number
    disk_type              = string
    availability_type      = string
    backup_enabled         = bool
    backup_start_time      = string
    point_in_time_recovery = bool
    high_availability      = bool
  })
  default = {
    database_version       = "POSTGRES_15"
    tier                   = "db-f1-micro"
    disk_size              = 10
    disk_type              = "PD_SSD"
    availability_type      = "ZONAL"
    backup_enabled         = true
    backup_start_time      = "03:00"
    point_in_time_recovery = true
    high_availability      = false
  }
}

# Storage configuration
variable "storage_config" {
  description = "Configuration for Cloud Storage buckets"
  type = object({
    storage_class      = string
    versioning_enabled = bool
    lifecycle_rules = list(object({
      age    = number
      action = string
    }))
    cors_origins = list(string)
  })
  default = {
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
    cors_origins = ["*"]
  }
}

# Pub/Sub topics configuration
variable "pubsub_topics" {
  description = "List of Pub/Sub topics to create"
  type = list(object({
    name                       = string
    message_retention_duration = string
    message_ordering           = bool
  }))
  default = [
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
      message_retention_duration = "86400s" # 1 day
      message_ordering           = false
    }
  ]
}

# Monitoring configuration
variable "monitoring_config" {
  description = "Configuration for monitoring and alerting"
  type = object({
    notification_channels = list(object({
      type  = string
      email = string
    }))
    alert_thresholds = object({
      cpu_utilization    = number
      memory_utilization = number
      disk_utilization   = number
      error_rate         = number
    })
  })
  default = {
    notification_channels = [
      {
        type  = "email"
        email = "alerts@example.com"
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