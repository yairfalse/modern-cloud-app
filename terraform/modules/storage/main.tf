# Storage module for ultra-budget configuration

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Media storage bucket for blog images
resource "google_storage_bucket" "media" {
  name          = "${var.name_prefix}-media-${var.project_id}"
  location      = var.region
  storage_class = "STANDARD"
  
  # Simple versioning
  versioning {
    enabled = false
  }
  
  # Basic CORS for image uploads
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
  
  # Basic lifecycle - delete old versions after 30 days
  lifecycle_rule {
    condition {
      age = 30
      with_state = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }
  
  labels = var.common_labels
  force_destroy = true
  project = var.project_id
}

# Backup bucket for database dumps
resource "google_storage_bucket" "backups" {
  name          = "${var.name_prefix}-backups-${var.project_id}"
  location      = var.region
  storage_class = "NEARLINE"
  
  # Keep versions for backups
  versioning {
    enabled = true
  }
  
  # Simple lifecycle - delete old backups after 90 days
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  labels = var.common_labels
  force_destroy = true
  project = var.project_id
}

# Static assets bucket for frontend
resource "google_storage_bucket" "static_assets" {
  name          = "${var.name_prefix}-static-${var.project_id}"
  location      = var.region
  storage_class = "STANDARD"
  
  # No versioning for static assets
  versioning {
    enabled = false
  }
  
  # Website configuration
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  
  # CORS for CDN
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["Content-Type", "Cache-Control"]
    max_age_seconds = 3600
  }
  
  labels = var.common_labels
  force_destroy = true
  project = var.project_id
}

# Allow public read access to media bucket (for blog images)
resource "google_storage_bucket_iam_member" "media_public_viewer" {
  bucket = google_storage_bucket.media.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Allow public read access to static assets
resource "google_storage_bucket_iam_member" "static_public_viewer" {
  bucket = google_storage_bucket.static_assets.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Service account for application access
resource "google_service_account" "storage_admin" {
  account_id   = "${substr(var.name_prefix, 0, 10)}-storage-sa"
  display_name = "Storage Admin for ${var.name_prefix}"
  project      = var.project_id
}

# Grant storage admin permissions to service account
resource "google_storage_bucket_iam_member" "media_admin" {
  bucket = google_storage_bucket.media.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.storage_admin.email}"
}

resource "google_storage_bucket_iam_member" "backups_admin" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.storage_admin.email}"
}

resource "google_storage_bucket_iam_member" "static_admin" {
  bucket = google_storage_bucket.static_assets.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.storage_admin.email}"
}