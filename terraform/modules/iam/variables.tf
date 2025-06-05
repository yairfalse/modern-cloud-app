# Variables for the IAM module

variable "project_id" {
  description = "The GCP project ID"
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