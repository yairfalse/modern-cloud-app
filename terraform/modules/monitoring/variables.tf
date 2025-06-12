# Variables for the Monitoring module

variable "project_id" {
  description = "The GCP project ID"
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

variable "gke_cluster_name" {
  description = "The name of the GKE cluster to monitor"
  type        = string
}

variable "database_instance_name" {
  description = "The name of the Cloud SQL instance to monitor"
  type        = string
}

variable "notification_config" {
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
}

variable "logs_bucket_name" {
  description = "The name of the storage bucket for logs"
  type        = string
  default     = ""
}