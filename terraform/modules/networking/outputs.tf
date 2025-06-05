# Outputs for the networking module

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnet_id" {
  description = "The ID of the primary subnet"
  value       = google_compute_subnetwork.primary.id
}

output "subnet_name" {
  description = "The name of the primary subnet"
  value       = google_compute_subnetwork.primary.name
}

output "subnet_self_link" {
  description = "The self link of the primary subnet"
  value       = google_compute_subnetwork.primary.self_link
}

output "pods_range_name" {
  description = "The name of the pods secondary range"
  value       = google_compute_subnetwork.primary.secondary_ip_range[0].range_name
}

output "services_range_name" {
  description = "The name of the services secondary range"
  value       = google_compute_subnetwork.primary.secondary_ip_range[1].range_name
}

output "private_vpc_connection" {
  description = "The private VPC connection for services"
  value       = google_service_networking_connection.private_vpc_connection.id
}

output "internal_dns_zone_name" {
  description = "The name of the internal DNS zone"
  value       = google_dns_managed_zone.internal.name
}

output "internal_dns_domain" {
  description = "The internal DNS domain"
  value       = google_dns_managed_zone.internal.dns_name
}