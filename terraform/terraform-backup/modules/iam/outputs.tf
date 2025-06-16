# Outputs for the IAM module

output "gke_service_account_email" {
  description = "The email of the GKE service account"
  value       = google_service_account.gke.email
}

output "gke_service_account_id" {
  description = "The ID of the GKE service account"
  value       = google_service_account.gke.id
}

output "app_service_account_email" {
  description = "The email of the application service account"
  value       = google_service_account.app.email
}

output "app_service_account_id" {
  description = "The ID of the application service account"
  value       = google_service_account.app.id
}

output "storage_admin_email" {
  description = "The email of the storage admin service account"
  value       = google_service_account.storage_admin.email
}

output "pubsub_service_account_email" {
  description = "The email of the Pub/Sub service account"
  value       = google_service_account.pubsub.email
}

output "monitoring_service_account_email" {
  description = "The email of the monitoring service account"
  value       = google_service_account.monitoring.email
}

output "backup_service_account_email" {
  description = "The email of the backup service account"
  value       = google_service_account.backup.email
}

output "cicd_service_account_email" {
  description = "The email of the CI/CD service account"
  value       = google_service_account.cicd.email
}

output "custom_developer_role_id" {
  description = "The ID of the custom developer role"
  value       = google_project_iam_custom_role.modernblog_developer.id
}

output "service_accounts" {
  description = "Map of all service account names to emails"
  value = {
    gke        = google_service_account.gke.email
    app        = google_service_account.app.email
    storage    = google_service_account.storage_admin.email
    pubsub     = google_service_account.pubsub.email
    monitoring = google_service_account.monitoring.email
    backup     = google_service_account.backup.email
    cicd       = google_service_account.cicd.email
  }
}

output "cicd_key_secret_id" {
  description = "The secret ID containing CI/CD service account key (if created)"
  value       = try(google_secret_manager_secret.cicd_credentials[0].secret_id, null)
}