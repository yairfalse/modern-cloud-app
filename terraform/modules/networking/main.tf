# VPC Networking module for ModernBlog
# Creates VPC, subnets, firewall rules, and network configurations

# VPC Network
resource "google_compute_network" "vpc" {
  name                            = "${var.name_prefix}-vpc"
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  mtu                             = 1460
  delete_default_routes_on_create = false
  
  project = var.project_id
}

# Primary subnet for GKE nodes and other resources
resource "google_compute_subnetwork" "primary" {
  name          = "${var.name_prefix}-subnet"
  ip_cidr_range = var.cidr_ranges.primary_subnet
  region        = var.region
  network       = google_compute_network.vpc.id
  
  # Secondary ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "${var.name_prefix}-pods"
    ip_cidr_range = var.cidr_ranges.pods_range
  }
  
  secondary_ip_range {
    range_name    = "${var.name_prefix}-services"
    ip_cidr_range = var.cidr_ranges.services_range
  }
  
  # Enable VPC flow logs for monitoring
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
  
  private_ip_google_access = true
  
  project = var.project_id
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  
  bgp {
    asn = 64514
  }
  
  project = var.project_id
}

# Cloud NAT for outbound connectivity
resource "google_compute_router_nat" "nat" {
  name                               = "${var.name_prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
  
  project = var.project_id
}

# Firewall rule to allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.name_prefix}-allow-internal"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = [
    var.cidr_ranges.primary_subnet,
    var.cidr_ranges.pods_range,
    var.cidr_ranges.services_range
  ]
  
  priority = 1000
  
  project = var.project_id
}

# Firewall rule to allow health checks
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.name_prefix}-allow-health-checks"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
  }
  
  # Google Cloud health check ranges
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
    "209.85.152.0/22",
    "209.85.204.0/22"
  ]
  
  target_tags = ["allow-health-checks"]
  
  priority = 1000
  
  project = var.project_id
}

# Firewall rule for SSH access (restricted)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.name_prefix}-allow-ssh"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  # Restrict SSH access - update with your IP ranges
  source_ranges = var.ssh_allowed_ranges
  
  target_tags = ["allow-ssh"]
  
  priority = 1000
  
  project = var.project_id
}

# Private Service Connection for Cloud SQL
resource "google_compute_global_address" "private_services" {
  name          = "${var.name_prefix}-private-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
  
  project = var.project_id
}

# Private VPC connection for services
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]
}

# DNS zone for internal resolution
resource "google_dns_managed_zone" "internal" {
  name        = "${var.name_prefix}-internal-dns"
  dns_name    = "${var.environment}.modernblog.internal."
  description = "Internal DNS zone for ${var.environment} environment"
  
  visibility = "private"
  
  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
  
  project = var.project_id
}