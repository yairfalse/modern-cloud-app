# Cloud Storage module for ModernBlog

# Media storage bucket
resource "google_storage_bucket" "media" {
  name          = "${var.name_prefix}-media-${var.project_id}"
  location      = var.region
  storage_class = var.storage_config.storage_class
  
  # Uniform bucket-level access
  uniform_bucket_level_access = true
  
  # Versioning
  versioning {
    enabled = var.storage_config.versioning_enabled
  }
  
  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = var.storage_config.lifecycle_rules
    content {
      condition {
        age = lifecycle_rule.value.age
      }
      action {
        type          = lifecycle_rule.value.action
        storage_class = can(regex("SetStorageClass:", lifecycle_rule.value.action)) ? split(":", lifecycle_rule.value.action)[1] : null
      }
    }
  }
  
  # CORS configuration
  cors {
    origin          = var.storage_config.cors_origins
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
  
  # Encryption
  encryption {
    default_kms_key_name = var.kms_key_name
  }
  
  # Soft delete policy
  soft_delete_policy {
    retention_duration_seconds = var.environment == "prod" ? 604800 : 86400 # 7 days for prod, 1 day for others
  }
  
  # Labels
  labels = var.common_labels
  
  # Prevent accidental deletion
  force_destroy = var.environment != "prod"
  
  project = var.project_id
}

# Backup bucket for database dumps and application backups
resource "google_storage_bucket" "backups" {
  name          = "${var.name_prefix}-backups-${var.project_id}"
  location      = var.region
  storage_class = "NEARLINE"
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  # Lifecycle rules for backups
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = var.environment == "prod" ? 2555 : 90 # 7 years for prod, 90 days for others
    }
    action {
      type = "Delete"
    }
  }
  
  # Encryption
  encryption {
    default_kms_key_name = var.kms_key_name
  }
  
  labels = var.common_labels
  
  force_destroy = var.environment != "prod"
  
  project = var.project_id
}

# Static assets bucket (for CDN)
resource "google_storage_bucket" "static_assets" {
  name          = "${var.name_prefix}-static-${var.project_id}"
  location      = var.region
  storage_class = "STANDARD"
  
  uniform_bucket_level_access = false # Allow public access for static assets
  
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
    response_header = ["Content-Type", "Cache-Control", "ETag"]
    max_age_seconds = 3600
  }
  
  labels = var.common_labels
  
  force_destroy = true
  
  project = var.project_id
}

# IAM bindings for media bucket
resource "google_storage_bucket_iam_member" "media_admin" {
  bucket = google_storage_bucket.media.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.storage_admin_email}"
}

resource "google_storage_bucket_iam_member" "media_viewer" {
  bucket = google_storage_bucket.media.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
  
  condition {
    title       = "Public read for images"
    description = "Allow public read access to image files"
    expression  = "resource.name.endsWith('.jpg') || resource.name.endsWith('.jpeg') || resource.name.endsWith('.png') || resource.name.endsWith('.gif') || resource.name.endsWith('.webp')"
  }
}

# IAM bindings for backup bucket
resource "google_storage_bucket_iam_member" "backup_admin" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.storage_admin_email}"
}

# IAM bindings for static assets bucket
resource "google_storage_bucket_iam_member" "static_viewer" {
  bucket = google_storage_bucket.static_assets.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Create initial folders in buckets
resource "google_storage_bucket_object" "media_folders" {
  for_each = toset([
    "images/",
    "videos/",
    "documents/",
    "thumbnails/"
  ])
  
  name    = each.value
  content = ""
  bucket  = google_storage_bucket.media.name
}

resource "google_storage_bucket_object" "backup_folders" {
  for_each = toset([
    "database/",
    "application/",
    "configurations/"
  ])
  
  name    = each.value
  content = ""
  bucket  = google_storage_bucket.backups.name
}

# CDN configuration for static assets
resource "google_compute_backend_bucket" "static_cdn" {
  name        = "${var.name_prefix}-static-cdn"
  description = "CDN backend for static assets"
  bucket_name = google_storage_bucket.static_assets.name
  enable_cdn  = true
  
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    client_ttl        = 3600
    default_ttl       = 3600
    max_ttl           = 86400
    negative_caching  = true
    serve_while_stale = 86400
  }
  
  project = var.project_id
}