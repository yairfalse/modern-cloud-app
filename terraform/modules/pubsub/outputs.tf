# Outputs for the Pub/Sub module

output "topic_ids" {
  description = "Map of topic names to their IDs"
  value = {
    for k, v in google_pubsub_topic.topics : k => v.id
  }
}

output "topic_names" {
  description = "Map of topic names to their full resource names"
  value = {
    for k, v in google_pubsub_topic.topics : k => v.name
  }
}

output "dead_letter_topic_ids" {
  description = "Map of dead letter topic names to their IDs"
  value = {
    for k, v in google_pubsub_topic.dead_letter : k => v.id
  }
}

output "subscription_ids" {
  description = "Map of subscription names to their IDs"
  value = merge(
    {
      for k, v in google_pubsub_subscription.push_subscriptions : "${k}-push" => v.id
    },
    {
      for k, v in google_pubsub_subscription.pull_subscriptions : "${k}-pull" => v.id
    }
  )
}

output "push_subscription_names" {
  description = "Map of push subscription names"
  value = {
    for k, v in google_pubsub_subscription.push_subscriptions : k => v.name
  }
}

output "pull_subscription_names" {
  description = "Map of pull subscription names"
  value = {
    for k, v in google_pubsub_subscription.pull_subscriptions : k => v.name
  }
}

output "bigquery_subscription_names" {
  description = "Map of BigQuery subscription names (if enabled)"
  value = {
    for k, v in google_pubsub_subscription.bigquery_subscriptions : k => v.name
  }
}

output "bigquery_dataset_id" {
  description = "The ID of the BigQuery dataset for analytics (if enabled)"
  value       = try(google_bigquery_dataset.pubsub_analytics[0].dataset_id, null)
}

output "topics_summary" {
  description = "Summary of all created topics with their configurations"
  value = {
    for k, v in google_pubsub_topic.topics : k => {
      id                         = v.id
      name                       = v.name
      push_subscription          = google_pubsub_subscription.push_subscriptions[k].name
      pull_subscription          = google_pubsub_subscription.pull_subscriptions[k].name
      dead_letter_topic          = google_pubsub_topic.dead_letter[k].name
      bigquery_subscription      = try(google_pubsub_subscription.bigquery_subscriptions[k].name, null)
    }
  }
}