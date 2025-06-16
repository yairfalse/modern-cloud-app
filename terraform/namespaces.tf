resource "kubernetes_namespace" "backend" {
  metadata { name = "backend" }
}

resource "kubernetes_namespace" "frontend" {
  metadata { name = "frontend" }
}

resource "kubernetes_namespace" "monitoring" {
  metadata { name = "monitoring" }
}