# Variables for development environment

variable "project_id" {
  description = "The GCP project ID for development"
  type        = string
}

variable "region" {
  description = "The GCP region for development resources"
  type        = string
  default     = "us-central1"
}

variable "team_name" {
  description = "Team name for resource labeling"
  type        = string
  default     = "platform-dev"
}

variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
}