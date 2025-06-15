# Outputs for the GKE module

output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The endpoint for the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate for the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "load_balancer_ip" {
  description = "The static IP address for the load balancer"
  value       = google_compute_address.ingress_ip.address
}

output "load_balancer_ip_name" {
  description = "The name of the static IP address resource"
  value       = google_compute_address.ingress_ip.name
}

output "node_pool_id" {
  description = "The ID of the primary node pool"
  value       = google_container_node_pool.primary_nodes.id
}

output "node_pool_name" {
  description = "The name of the primary node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "workload_identity_pool" {
  description = "The workload identity pool for the cluster"
  value       = "${var.project_id}.svc.id.goog"
}