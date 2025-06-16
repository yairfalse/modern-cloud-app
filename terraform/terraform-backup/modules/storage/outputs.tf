# Outputs for the Storage module

output "media_bucket_name" {
  description = "The name of the media storage bucket"
  value       = google_storage_bucket.media.name
}

output "media_bucket_url" {
  description = "The URL of the media storage bucket"
  value       = google_storage_bucket.media.url
}

output "media_bucket_self_link" {
  description = "The self link of the media storage bucket"
  value       = google_storage_bucket.media.self_link
}

output "backups_bucket_name" {
  description = "The name of the backups storage bucket"
  value       = google_storage_bucket.backups.name
}

output "backups_bucket_url" {
  description = "The URL of the backups storage bucket"
  value       = google_storage_bucket.backups.url
}

output "static_assets_bucket_name" {
  description = "The name of the static assets bucket"
  value       = google_storage_bucket.static_assets.name
}

output "static_assets_bucket_url" {
  description = "The URL of the static assets bucket"
  value       = google_storage_bucket.static_assets.url
}

output "static_cdn_backend_name" {
  description = "The name of the CDN backend bucket"
  value       = google_compute_backend_bucket.static_cdn.name
}

output "static_cdn_self_link" {
  description = "The self link of the CDN backend bucket"
  value       = google_compute_backend_bucket.static_cdn.self_link
}

output "bucket_names" {
  description = "Map of all bucket names"
  value = {
    media         = google_storage_bucket.media.name
    backups       = google_storage_bucket.backups.name
    static_assets = google_storage_bucket.static_assets.name
  }
}