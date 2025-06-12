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
    database_version     = string
    tier                 = string
    disk_size            = number
    disk_type            = string
    availability_type    = string
    backup_enabled       = bool
    backup_start_time    = string
    point_in_time_recovery = bool
    high_availability    = bool
  })
  default = {
    database_version     = "POSTGRES_15"
    tier                 = "db-f1-micro"
    disk_size            = 10
    disk_type            = "PD_SSD"
    availability_type    = "ZONAL"
    backup_enabled       = true
    backup_start_time    = "03:00"
    point_in_time_recovery = true
    high_availability    = false
  }
}

# Pub/Sub topics configuration
variable "pubsub_topics" {
  description = "List of Pub/Sub topics to create"
  type = list(object({
    name                       = string
    message_retention_duration = string
    message_ordering          = bool
  }))
  default = [
    {
      name                       = "user-notifications"
      message_retention_duration = "604800s" # 7 days
      message_ordering          = false
    },
    {
      name                       = "content-updates"
      message_retention_duration = "604800s"
      message_ordering          = true
    },
    {
      name                       = "analytics-events"
      message_retention_duration = "86400s" # 1 day
      message_ordering          = false
    }
  ]
}