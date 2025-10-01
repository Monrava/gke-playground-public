data "google_client_config" "default" {}

provider "google" {
  alias   = "gcp"
  project = data.google_client_config.default.project
  region  = data.google_client_config.default.region
  zone    = data.google_client_config.default.zone
  user_project_override = true
  billing_project = var.project-id
}

terraform {
  backend "gcs" {
    prefix  = "terraform/state"
  }
}
provider "kubernetes" {
  host                   = "https://${google_container_cluster.insecure_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.insecure_cluster.master_auth.0.cluster_ca_certificate)
}
