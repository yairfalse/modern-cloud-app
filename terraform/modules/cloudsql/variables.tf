# Variables for the Cloud SQL module

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_labels" {
  description = "Common labels to apply to resources"
  type        = map(string)
}

variable "network_id" {
  description = "The VPC network ID for private IP configuration"
  type        = string
}

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
}