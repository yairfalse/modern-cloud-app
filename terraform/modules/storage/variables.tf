# Variables for the Storage module

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
}

variable "storage_admin_email" {
  description = "The service account email for storage administration"
  type        = string
}

variable "kms_key_name" {
  description = "The KMS key name for bucket encryption"
  type        = string
  default     = null
}