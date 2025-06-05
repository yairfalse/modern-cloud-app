# IAM module for ModernBlog - Service accounts and roles

# GKE Service Account
resource "google_service_account" "gke" {
  account_id   = "${var.name_prefix}-gke-sa"
  display_name = "GKE Service Account for ${var.environment}"
  description  = "Service account for GKE nodes and workload identity"
  
  project = var.project_id
}

# GKE Service Account IAM roles
resource "google_project_iam_member" "gke_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
    "roles/storage.objectViewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke.email}"
}

# Application Service Account (for Workload Identity)
resource "google_service_account" "app" {
  account_id   = "${var.name_prefix}-app-sa"
  display_name = "Application Service Account for ${var.environment}"
  description  = "Service account for ModernBlog application workloads"
  
  project = var.project_id
}

# Application Service Account IAM roles
resource "google_project_iam_member" "app_roles" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/storage.objectAdmin",
    "roles/pubsub.publisher",
    "roles/pubsub.subscriber",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Storage Admin Service Account
resource "google_service_account" "storage_admin" {
  account_id   = "${var.name_prefix}-storage-admin-sa"
  display_name = "Storage Admin Service Account for ${var.environment}"
  description  = "Service account for managing storage buckets and objects"
  
  project = var.project_id
}

# Storage Admin IAM roles
resource "google_project_iam_member" "storage_admin_roles" {
  for_each = toset([
    "roles/storage.admin",
    "roles/storage.objectAdmin"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.storage_admin.email}"
}

# Pub/Sub Service Account
resource "google_service_account" "pubsub" {
  account_id   = "${var.name_prefix}-pubsub-sa"
  display_name = "Pub/Sub Service Account for ${var.environment}"
  description  = "Service account for Pub/Sub operations"
  
  project = var.project_id
}

# Pub/Sub Service Account IAM roles
resource "google_project_iam_member" "pubsub_roles" {
  for_each = toset([
    "roles/pubsub.admin",
    "roles/pubsub.publisher",
    "roles/pubsub.subscriber"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.pubsub.email}"
}

# Monitoring Service Account
resource "google_service_account" "monitoring" {
  account_id   = "${var.name_prefix}-monitoring-sa"
  display_name = "Monitoring Service Account for ${var.environment}"
  description  = "Service account for monitoring and alerting"
  
  project = var.project_id
}

# Monitoring Service Account IAM roles
resource "google_project_iam_member" "monitoring_roles" {
  for_each = toset([
    "roles/monitoring.viewer",
    "roles/monitoring.metricWriter",
    "roles/logging.viewer",
    "roles/cloudtrace.user"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.monitoring.email}"
}

# Backup Service Account
resource "google_service_account" "backup" {
  account_id   = "${var.name_prefix}-backup-sa"
  display_name = "Backup Service Account for ${var.environment}"
  description  = "Service account for backup operations"
  
  project = var.project_id
}

# Backup Service Account IAM roles
resource "google_project_iam_member" "backup_roles" {
  for_each = toset([
    "roles/cloudsql.viewer",
    "roles/storage.objectCreator",
    "roles/storage.objectViewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.backup.email}"
}

# Workload Identity binding for app service account
resource "google_service_account_iam_member" "workload_identity_app" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[modernblog/modernblog-app]"
}

# Create custom IAM role for minimal permissions
resource "google_project_iam_custom_role" "modernblog_developer" {
  role_id     = "${replace(var.name_prefix, "-", "_")}_developer"
  title       = "ModernBlog Developer Role for ${var.environment}"
  description = "Custom role for ModernBlog developers with minimal required permissions"
  
  permissions = [
    # Kubernetes access
    "container.clusters.get",
    "container.clusters.getCredentials",
    "container.pods.get",
    "container.pods.list",
    "container.services.get",
    "container.services.list",
    
    # Logging access
    "logging.logEntries.list",
    "logging.logs.list",
    
    # Monitoring access
    "monitoring.timeSeries.list",
    "monitoring.metricDescriptors.list",
    
    # Storage access (read-only)
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.get",
    "storage.objects.list",
    
    # Cloud SQL access (read-only)
    "cloudsql.instances.get",
    "cloudsql.instances.list",
    
    # Secret Manager access (read-only)
    "secretmanager.secrets.get",
    "secretmanager.secrets.list",
    "secretmanager.versions.access"
  ]
  
  project = var.project_id
}

# Service account for CI/CD
resource "google_service_account" "cicd" {
  account_id   = "${var.name_prefix}-cicd-sa"
  display_name = "CI/CD Service Account for ${var.environment}"
  description  = "Service account for CI/CD pipelines"
  
  project = var.project_id
}

# CI/CD Service Account IAM roles
resource "google_project_iam_member" "cicd_roles" {
  for_each = toset([
    "roles/container.developer",
    "roles/storage.admin",
    "roles/artifactregistry.writer",
    "roles/cloudbuild.builds.editor",
    "roles/iam.serviceAccountUser"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cicd.email}"
}

# Generate service account keys for external use (only in non-prod)
resource "google_service_account_key" "cicd_key" {
  count              = var.environment != "prod" ? 1 : 0
  service_account_id = google_service_account.cicd.email
  
  keepers = {
    rotation = formatdate("YYYY-MM", timestamp())
  }
}

# Store CI/CD credentials in Secret Manager
resource "google_secret_manager_secret" "cicd_credentials" {
  count     = var.environment != "prod" ? 1 : 0
  secret_id = "${var.name_prefix}-cicd-credentials"
  
  replication {
    auto {}
  }
  
  labels = var.common_labels
  
  project = var.project_id
}

resource "google_secret_manager_secret_version" "cicd_credentials" {
  count  = var.environment != "prod" ? 1 : 0
  secret = google_secret_manager_secret.cicd_credentials[0].id
  
  secret_data = base64decode(google_service_account_key.cicd_key[0].private_key)
}