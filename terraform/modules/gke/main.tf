# GKE Cluster module for ModernBlog
# Creates GKE cluster with Cilium CNI (Dataplane V2) enabled

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.name_prefix}-gke"
  location = var.region
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Network configuration
  network    = var.network
  subnetwork = var.subnetwork
  
  # Cluster configuration
  min_master_version = var.cluster_config.k8s_version_prefix
  release_channel {
    channel = var.cluster_config.release_channel
  }
  
  # Enable Dataplane V2 (Cilium)
  datapath_provider = "ADVANCED_DATAPATH"
  
  # IP allocation policy for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }
  
  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Network policy configuration
  network_policy {
    enabled  = true
    provider = "CALICO" # This is overridden by Cilium when datapath_provider is ADVANCED_DATAPATH
  }
  
  # Add-on configuration
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    
    http_load_balancing {
      disabled = false
    }
    
    network_policy_config {
      disabled = false
    }
    
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    
    dns_cache_config {
      enabled = true
    }
  }
  
  # Binary Authorization
  binary_authorization {
    evaluation_mode = var.environment == "prod" ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }
  
  # Master authorized networks
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }
  
  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
  
  # Cluster autoscaling
  cluster_autoscaling {
    enabled = true
    
    resource_limits {
      resource_type = "cpu"
      minimum       = 4
      maximum       = 100
    }
    
    resource_limits {
      resource_type = "memory"
      minimum       = 16
      maximum       = 400
    }
    
    auto_provisioning_defaults {
      service_account = var.service_account_email
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
      
      management {
        auto_repair  = true
        auto_upgrade = true
      }
      
      shielded_instance_config {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }
    }
  }
  
  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
    
    maintenance_exclusion {
      exclusion_name = "holiday-freeze"
      start_time     = "2024-12-23T00:00:00Z"
      end_time       = "2025-01-02T00:00:00Z"
      exclusion_options {
        scope = "NO_UPGRADES"
      }
    }
  }
  
  # Security configuration
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  
  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    
    managed_prometheus {
      enabled = true
    }
  }
  
  # Resource labels
  resource_labels = var.common_labels
  
  project = var.project_id
}

# Primary node pool
resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.name_prefix}-node-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name
  
  # Autoscaling configuration
  autoscaling {
    min_node_count = var.cluster_config.min_node_count
    max_node_count = var.cluster_config.max_node_count
  }
  
  # Node configuration
  node_config {
    preemptible  = var.environment != "prod"
    machine_type = var.cluster_config.machine_type
    
    disk_size_gb = var.cluster_config.disk_size_gb
    disk_type    = var.cluster_config.disk_type
    
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = var.service_account_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    # Security configuration
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
    
    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    # Node labels
    labels = merge(var.common_labels, {
      node_pool = "primary"
    })
    
    # Node taints for dedicated workloads
    dynamic "taint" {
      for_each = var.node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
    
    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    tags = ["gke-node", "${var.name_prefix}-gke-node", "allow-health-checks"]
  }
  
  # Management configuration
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }
  
  project = var.project_id
}

# Static IP for Load Balancer
resource "google_compute_address" "ingress_ip" {
  name         = "${var.name_prefix}-ingress-ip"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
  region       = var.region
  
  project = var.project_id
}

# Configure kubectl context
resource "null_resource" "configure_kubectl" {
  triggers = {
    cluster_id = google_container_cluster.primary.id
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      gcloud container clusters get-credentials ${google_container_cluster.primary.name} \
        --region ${var.region} \
        --project ${var.project_id}
    EOT
  }
  
  depends_on = [google_container_cluster.primary, google_container_node_pool.primary_nodes]
}