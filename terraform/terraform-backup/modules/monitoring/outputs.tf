# Outputs for the Monitoring module

output "dashboard_id" {
  description = "The ID of the monitoring dashboard"
  value       = google_monitoring_dashboard.main.id
}

output "dashboard_name" {
  description = "The name of the monitoring dashboard"
  value       = google_monitoring_dashboard.main.dashboard_json
}

output "notification_channel_ids" {
  description = "Map of notification channel IDs"
  value = {
    for k, v in google_monitoring_notification_channel.email : k => v.id
  }
}

output "alert_policy_ids" {
  description = "Map of alert policy names to their IDs"
  value = {
    gke_cpu_high      = google_monitoring_alert_policy.gke_cpu_high.id
    gke_memory_high   = google_monitoring_alert_policy.gke_memory_high.id
    database_cpu_high = google_monitoring_alert_policy.database_cpu_high.id
    error_rate_high   = google_monitoring_alert_policy.error_rate_high.id
  }
}

output "uptime_check_id" {
  description = "The ID of the uptime check"
  value       = google_monitoring_uptime_check_config.app_health.id
}

output "log_sink_name" {
  description = "The name of the log sink"
  value       = google_logging_project_sink.all_logs.name
}

output "log_sink_writer_identity" {
  description = "The writer identity for the log sink"
  value       = google_logging_project_sink.all_logs.writer_identity
}

output "error_metric_name" {
  description = "The name of the error count metric"
  value       = google_logging_metric.error_count.name
}

output "workspace_id" {
  description = "The workspace ID for monitoring"
  value       = var.project_id # In GCP, workspace ID is the project ID
}