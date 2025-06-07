# Output values for the ModernBlog infrastructure

# Network outputs
output "network_name" {
  description = "The name of the VPC network"
  value       = module.networking.network_name
}

output "subnet_name" {
  description = "The name of the primary subnet"
  value       = module.networking.subnet_name
}

# GKE outputs
output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint for the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "The CA certificate for the GKE cluster"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "gke_service_account_email" {
  description = "The email of the GKE service account"
  value       = module.iam.gke_service_account_email
}

# Database outputs
output "database_instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = module.cloudsql.instance_name
}

output "database_connection_name" {
  description = "The connection name for the Cloud SQL instance"
  value       = module.cloudsql.connection_name
}

output "database_private_ip" {
  description = "The private IP address of the Cloud SQL instance"
  value       = module.cloudsql.private_ip
}

output "database_name" {
  description = "The name of the PostgreSQL database"
  value       = module.cloudsql.database_name
}

# Storage outputs
output "media_bucket_name" {
  description = "The name of the media storage bucket"
  value       = module.storage.media_bucket_name
}

output "media_bucket_url" {
  description = "The URL of the media storage bucket"
  value       = module.storage.media_bucket_url
}

# Pub/Sub outputs
output "pubsub_topics" {
  description = "Map of Pub/Sub topic names to their IDs"
  value       = module.pubsub.topic_ids
}

output "pubsub_subscriptions" {
  description = "Map of Pub/Sub subscription names to their IDs"
  value       = module.pubsub.subscription_ids
}

# Load balancer outputs
output "load_balancer_ip" {
  description = "The IP address of the load balancer"
  value       = module.gke.load_balancer_ip
}

# Service account outputs
output "service_accounts" {
  description = "Map of service account names to their emails"
  value = {
    gke     = module.iam.gke_service_account_email
    storage = module.iam.storage_admin_email
    pubsub  = module.iam.pubsub_service_account_email
    app     = module.iam.app_service_account_email
  }
}


# Connection information for applications
output "app_config" {
  description = "Configuration values for applications"
  value = {
    project_id               = var.project_id
    region                   = var.region
    environment              = var.environment
    gke_cluster_name         = module.gke.cluster_name
    database_connection_name = module.cloudsql.connection_name
    database_name            = module.cloudsql.database_name
    media_bucket_name        = module.storage.media_bucket_name
    pubsub_topics            = module.pubsub.topic_ids
  }
  sensitive = false
}