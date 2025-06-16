resource "google_sql_database_instance" "main" {
  name             = "${var.name_prefix}-db-instance"
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_15"

  settings {
    tier      = "db-f1-micro"
    disk_size = 10
    disk_type = "PD_SSD"
  }

  deletion_protection = false
}

resource "google_sql_database" "database" {
  name     = "${var.name_prefix}-db"
  project  = var.project_id
  instance = google_sql_database_instance.main.name
}