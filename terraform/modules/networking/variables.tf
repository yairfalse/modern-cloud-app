# Variables for the networking module

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

variable "cidr_ranges" {
  description = "CIDR ranges for VPC subnets"
  type = object({
    primary_subnet = string
    pods_range     = string
    services_range = string
  })
}

variable "ssh_allowed_ranges" {
  description = "IP ranges allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production
}