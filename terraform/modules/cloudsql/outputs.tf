# Outputs for the Cloud SQL module

output "instance_id" {
  description = "The ID of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.id
}

output "instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.name
}

output "connection_name" {
  description = "The connection name for the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.connection_name
}

output "private_ip" {
  description = "The private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "database_name" {
  description = "The name of the PostgreSQL database"
  value       = google_sql_database.modernblog.name
}

output "database_version" {
  description = "The PostgreSQL version"
  value       = google_sql_database_instance.postgres.database_version
}

output "credentials_secret_id" {
  description = "The ID of the secret containing database credentials"
  value       = google_secret_manager_secret.db_credentials.secret_id
}

output "readonly_credentials_secret_id" {
  description = "The ID of the secret containing read-only database credentials"
  value       = google_secret_manager_secret.readonly_credentials.secret_id
}

output "replica_instance_name" {
  description = "The name of the read replica instance (if created)"
  value       = try(google_sql_database_instance.read_replica[0].name, null)
}

output "replica_connection_name" {
  description = "The connection name for the read replica (if created)"
  value       = try(google_sql_database_instance.read_replica[0].connection_name, null)
}