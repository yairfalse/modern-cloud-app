# Monitoring module for ModernBlog

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Create a monitoring workspace
resource "google_monitoring_dashboard" "main" {
  dashboard_json = jsonencode({
    displayName = "${var.name_prefix}-dashboard"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          xPos   = 0
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "GKE Cluster CPU Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_cluster\" AND resource.labels.cluster_name=\"${var.gke_cluster_name}\" AND metric.type=\"kubernetes.io/container/cpu/core_usage_time\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields      = ["resource.cluster_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "CPU cores"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          xPos   = 6
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "GKE Cluster Memory Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_cluster\" AND resource.labels.cluster_name=\"${var.gke_cluster_name}\" AND metric.type=\"kubernetes.io/container/memory/used_bytes\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields      = ["resource.cluster_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Memory (bytes)"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          xPos   = 0
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Cloud SQL CPU Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=~\".*${var.database_instance_name}.*\" AND metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "CPU Utilization"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Cloud SQL Connections"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=~\".*${var.database_instance_name}.*\" AND metric.type=\"cloudsql.googleapis.com/database/postgresql/num_backends\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Active Connections"
                scale = "LINEAR"
              }
            }
          }
        }
      ]
    }
  })
  
  project = var.project_id
}

# Notification channels
resource "google_monitoring_notification_channel" "email" {
  for_each = { for idx, channel in var.notification_config.notification_channels : idx => channel if channel.type == "email" }
  
  display_name = "${var.name_prefix}-email-${each.key}"
  type         = "email"
  
  labels = {
    email_address = each.value.email
  }
  
  user_labels = var.common_labels
  
  project = var.project_id
}

# Create a log-based metric for error tracking
resource "google_logging_metric" "error_count" {
  name   = "${var.name_prefix}-error-count"
  filter = "severity >= ERROR AND resource.type=\"k8s_container\""
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key         = "severity"
      value_type  = "STRING"
      description = "The severity of the log entry"
    }
  }
  
  label_extractors = {
    "severity" = "EXTRACT(severity)"
  }
  
  project = var.project_id
}

# Alert policies
resource "google_monitoring_alert_policy" "gke_cpu_high" {
  display_name = "${var.name_prefix}-gke-cpu-high"
  combiner     = "OR"
  
  conditions {
    display_name = "GKE Cluster CPU usage is high"
    
    condition_threshold {
      filter          = "resource.type=\"k8s_cluster\" AND resource.labels.cluster_name=\"${var.gke_cluster_name}\" AND metric.type=\"kubernetes.io/container/cpu/core_usage_time\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.notification_config.alert_thresholds.cpu_utilization / 100
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.cluster_name"]
      }
    }
  }
  
  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.id]
  
  alert_strategy {
    auto_close = "86400s" # 24 hours
    
    notification_rate_limit {
      period = "3600s" # 1 hour
    }
  }
  
  documentation {
    content   = "The GKE cluster ${var.gke_cluster_name} CPU usage has exceeded ${var.notification_config.alert_thresholds.cpu_utilization}%"
    mime_type = "text/markdown"
  }
  
  user_labels = var.common_labels
  
  project = var.project_id
}

resource "google_monitoring_alert_policy" "gke_memory_high" {
  display_name = "${var.name_prefix}-gke-memory-high"
  combiner     = "OR"
  
  conditions {
    display_name = "GKE Cluster memory usage is high"
    
    condition_threshold {
      filter          = "resource.type=\"k8s_cluster\" AND resource.labels.cluster_name=\"${var.gke_cluster_name}\" AND metric.type=\"kubernetes.io/container/memory/used_bytes\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.notification_config.alert_thresholds.memory_utilization * 1073741824 / 100 # Convert percentage to bytes
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.cluster_name"]
      }
    }
  }
  
  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.id]
  
  alert_strategy {
    auto_close = "86400s"
    
    notification_rate_limit {
      period = "3600s"
    }
  }
  
  documentation {
    content   = "The GKE cluster ${var.gke_cluster_name} memory usage has exceeded ${var.notification_config.alert_thresholds.memory_utilization}%"
    mime_type = "text/markdown"
  }
  
  user_labels = var.common_labels
  
  project = var.project_id
}

resource "google_monitoring_alert_policy" "database_cpu_high" {
  display_name = "${var.name_prefix}-database-cpu-high"
  combiner     = "OR"
  
  conditions {
    display_name = "Cloud SQL CPU usage is high"
    
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=~\".*${var.database_instance_name}.*\" AND metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.notification_config.alert_thresholds.cpu_utilization / 100
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.id]
  
  alert_strategy {
    auto_close = "86400s"
    
    notification_rate_limit {
      period = "3600s"
    }
  }
  
  documentation {
    content   = "The Cloud SQL instance ${var.database_instance_name} CPU usage has exceeded ${var.notification_config.alert_thresholds.cpu_utilization}%"
    mime_type = "text/markdown"
  }
  
  user_labels = var.common_labels
  
  project = var.project_id
}

resource "google_monitoring_alert_policy" "error_rate_high" {
  display_name = "${var.name_prefix}-error-rate-high"
  combiner     = "OR"
  
  conditions {
    display_name = "Error rate is high"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.error_count.name}\" AND resource.type=\"k8s_container\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.notification_config.alert_thresholds.error_rate
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }
  
  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.id]
  
  alert_strategy {
    auto_close = "86400s"
    
    notification_rate_limit {
      period = "900s" # 15 minutes for error alerts
    }
  }
  
  documentation {
    content   = "The error rate has exceeded ${var.notification_config.alert_thresholds.error_rate} errors per second"
    mime_type = "text/markdown"
  }
  
  user_labels = var.common_labels
  
  project = var.project_id
}

# Uptime checks
resource "google_monitoring_uptime_check_config" "app_health" {
  display_name = "${var.name_prefix}-app-health"
  timeout      = "10s"
  period       = "60s"
  
  http_check {
    path           = "/health"
    port           = "443"
    use_ssl        = true
    validate_ssl   = true
    request_method = "GET"
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = "${var.name_prefix}.example.com" # Update with actual domain
    }
  }
  
  selected_regions = [
    "USA",
    "EUROPE",
    "ASIA_PACIFIC"
  ]
  
  project = var.project_id
}

# Create a log sink for long-term storage
resource "google_logging_project_sink" "all_logs" {
  name        = "${var.name_prefix}-all-logs"
  destination = "storage.googleapis.com/${var.logs_bucket_name}"
  
  filter = "resource.type=\"k8s_cluster\" OR resource.type=\"cloudsql_database\" OR resource.type=\"gcs_bucket\""
  
  unique_writer_identity = true
  
  project = var.project_id
}

# Grant the sink writer permissions
resource "google_storage_bucket_iam_member" "log_sink_writer" {
  bucket = var.logs_bucket_name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.all_logs.writer_identity
}