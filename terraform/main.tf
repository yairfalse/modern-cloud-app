provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gke-gcloud-auth-plugin"
  }
}

module "networking" {
  source      = "./modules/networking"
  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
}

module "gke" {
  source      = "./modules/gke"
  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
}

module "database" {
  source      = "./modules/database"
  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
}

module "storage" {
  source      = "./modules/storage"
  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
}