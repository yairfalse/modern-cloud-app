# Variables for production environment

variable "project_id" {
  description = "The GCP project ID for production"
  type        = string
}

variable "region" {
  description = "The GCP region for production resources"
  type        = string
  default     = "us-central1"
}

variable "team_name" {
  description = "Team name for resource labeling"
  type        = string
  default     = "platform-prod"
}

variable "alert_emails" {
  description = "List of email addresses for monitoring alerts"
  type        = list(string)
}

variable "pagerduty_enabled" {
  description = "Enable PagerDuty integration for alerts"
  type        = bool
  default     = false
}

variable "pagerduty_email" {
  description = "PagerDuty integration email"
  type        = string
  default     = ""
}