# Pub/Sub module for ModernBlog

# Create Pub/Sub topics
resource "google_pubsub_topic" "topics" {
  for_each = { for topic in var.topics : topic.name => topic }
  
  name = "${var.name_prefix}-${each.value.name}"
  
  # Message retention
  message_retention_duration = each.value.message_retention_duration
  
  # Message ordering
  dynamic "message_storage_policy" {
    for_each = each.value.message_ordering ? [1] : []
    content {
      allowed_persistence_regions = [var.region]
    }
  }
  
  # Schema settings (if needed in future)
  # schema_settings {
  #   schema = google_pubsub_schema.example.id
  #   encoding = "JSON"
  # }
  
  labels = merge(var.common_labels, {
    topic = each.value.name
  })
  
  project = var.project_id
}

# Create dead letter topics for each main topic
resource "google_pubsub_topic" "dead_letter" {
  for_each = { for topic in var.topics : topic.name => topic }
  
  name = "${var.name_prefix}-${each.value.name}-dlq"
  
  message_retention_duration = "604800s" # 7 days
  
  labels = merge(var.common_labels, {
    topic = "${each.value.name}-dlq"
    type  = "dead-letter"
  })
  
  project = var.project_id
}

# Create subscriptions for each topic
resource "google_pubsub_subscription" "push_subscriptions" {
  for_each = { for topic in var.topics : topic.name => topic }
  
  name  = "${var.name_prefix}-${each.value.name}-push-sub"
  topic = google_pubsub_topic.topics[each.key].name
  
  # Message retention
  message_retention_duration = "604800s" # 7 days
  retain_acked_messages      = false
  
  # Acknowledgement deadline
  ack_deadline_seconds = 60
  
  # Enable message ordering if configured
  enable_message_ordering = each.value.message_ordering
  
  # Expiration policy
  expiration_policy {
    ttl = "2592000s" # 30 days
  }
  
  # Dead letter policy
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter[each.key].id
    max_delivery_attempts = 5
  }
  
  # Retry policy
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
  
  # Push configuration (to be configured by applications)
  # push_config {
  #   push_endpoint = "https://example.com/push"
  #   
  #   oidc_token {
  #     service_account_email = var.pubsub_service_account_email
  #   }
  # }
  
  labels = merge(var.common_labels, {
    subscription = "${each.value.name}-push"
    type        = "push"
  })
  
  project = var.project_id
}

# Create pull subscriptions for each topic
resource "google_pubsub_subscription" "pull_subscriptions" {
  for_each = { for topic in var.topics : topic.name => topic }
  
  name  = "${var.name_prefix}-${each.value.name}-pull-sub"
  topic = google_pubsub_topic.topics[each.key].name
  
  # Message retention
  message_retention_duration = "604800s" # 7 days
  retain_acked_messages      = true
  
  # Acknowledgement deadline
  ack_deadline_seconds = 600 # 10 minutes for pull subscriptions
  
  # Enable message ordering if configured
  enable_message_ordering = each.value.message_ordering
  
  # Expiration policy
  expiration_policy {
    ttl = "2592000s" # 30 days
  }
  
  # Dead letter policy
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter[each.key].id
    max_delivery_attempts = 10
  }
  
  # Retry policy
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
  
  labels = merge(var.common_labels, {
    subscription = "${each.value.name}-pull"
    type        = "pull"
  })
  
  project = var.project_id
}

# IAM bindings for topics
resource "google_pubsub_topic_iam_member" "publisher" {
  for_each = { for topic in var.topics : topic.name => topic }
  
  topic  = google_pubsub_topic.topics[each.key].name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${var.pubsub_service_account_email}"
  
  project = var.project_id
}

# IAM bindings for subscriptions
resource "google_pubsub_subscription_iam_member" "subscriber_push" {
  for_each = { for topic in var.topics : topic.name => topic }
  
  subscription = google_pubsub_subscription.push_subscriptions[each.key].name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.pubsub_service_account_email}"
  
  project = var.project_id
}

resource "google_pubsub_subscription_iam_member" "subscriber_pull" {
  for_each = { for topic in var.topics : topic.name => topic }
  
  subscription = google_pubsub_subscription.pull_subscriptions[each.key].name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.pubsub_service_account_email}"
  
  project = var.project_id
}

# Create a BigQuery dataset for Pub/Sub analytics (optional)
resource "google_bigquery_dataset" "pubsub_analytics" {
  count = var.enable_analytics ? 1 : 0
  
  dataset_id                  = "${replace(var.name_prefix, "-", "_")}_pubsub_analytics"
  friendly_name               = "Pub/Sub Analytics for ${var.environment}"
  description                 = "Dataset for storing Pub/Sub message analytics"
  location                    = var.region
  default_table_expiration_ms = 7776000000 # 90 days
  
  labels = var.common_labels
  
  access {
    role          = "OWNER"
    user_by_email = var.pubsub_service_account_email
  }
  
  project = var.project_id
}

# BigQuery subscription for analytics
resource "google_pubsub_subscription" "bigquery_subscriptions" {
  for_each = var.enable_analytics ? { for topic in var.topics : topic.name => topic } : {}
  
  name  = "${var.name_prefix}-${each.value.name}-bq-sub"
  topic = google_pubsub_topic.topics[each.key].name
  
  bigquery_config {
    table = "${google_bigquery_dataset.pubsub_analytics[0].project}:${google_bigquery_dataset.pubsub_analytics[0].dataset_id}.${replace(each.value.name, "-", "_")}_messages"
    
    # Write metadata
    write_metadata = true
  }
  
  # No expiration for BigQuery subscriptions
  expiration_policy {
    ttl = ""
  }
  
  labels = merge(var.common_labels, {
    subscription = "${each.value.name}-bigquery"
    type        = "bigquery"
  })
  
  project = var.project_id
}