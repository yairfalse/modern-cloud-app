# Variables for the Pub/Sub module

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
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

variable "topics" {
  description = "List of Pub/Sub topics to create"
  type = list(object({
    name                       = string
    message_retention_duration = string
    message_ordering          = bool
  }))
}

variable "pubsub_service_account_email" {
  description = "The service account email for Pub/Sub operations"
  type        = string
}

variable "enable_analytics" {
  description = "Enable BigQuery analytics for Pub/Sub messages"
  type        = bool
  default     = false
}