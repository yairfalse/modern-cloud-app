resource "google_container_cluster" "primary" {
  name     = "${var.name_prefix}-cluster"
  project  = var.project_id
  location = var.region

  initial_node_count       = 2
  remove_default_node_pool = true

  network    = "${var.name_prefix}-vpc"
  subnetwork = "${var.name_prefix}-subnet"
}

resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.name_prefix}-node-pool"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.primary.name

  node_count = 2

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 30
    disk_type    = "pd-standard"
  }
}