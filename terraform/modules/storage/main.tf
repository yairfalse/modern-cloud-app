resource "google_storage_bucket" "main" {
  name     = "${var.name_prefix}-storage-${var.project_id}"
  project  = var.project_id
  location = var.region

  uniform_bucket_level_access = true
  force_destroy               = true
}