#################################################################################
# Define required providers
#################################################################################
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}
#################################################################################
# Define variables
#################################################################################
variable "list_of_roles_to_grant_to_service_account_tf_avml" {
  # Description: These are the roles we want to grant to service account: demo-automation-nonprod-sa
  description = "IAM roles to grant to the service account"
  type        = list(string)
  # The below roles are all the permissions that we want the service account to have.
  default = [
    "roles/viewer",
    "roles/storage.objectViewer",
    "roles/storage.objectCreator", # Needed to upload AVML file to GCS bucket
    "roles/compute.instanceAdmin.v1", # This is needed to grant the compute.images.create permission. https://cloud.google.com/compute/docs/reference/rest/v1/images/insert
  ]
}
# Your cluster need a service account attached if you want it to be able to pull images in GCR
resource "google_service_account" "tf-avml-sa" {
  account_id    = var.new_service_account_name
  project       = var.project-id
  display_name  = "Service Account: tf-avml-sa"
  description   = "A service account for AVML instance."
}


# Assign role bindings for all IAM roles
resource "google_project_iam_member" "roles_to_grant_to_service_account_tf_avml" {
  # Description: Creates IAM bindings (IAM Policy) for all roles related to demo-automation-nonprod-sa
  # to have in our IR project: demo-automation-nonprod
  project  = var.project-id
  member   = "serviceAccount:${google_service_account.tf-avml-sa.email}"
  for_each = toset(var.list_of_roles_to_grant_to_service_account_tf_avml)
  role     = each.value
}

# Create AVML bucket
resource "google_storage_bucket" "demo-avml-bucket" {
  name          = "demo-avml-bucket"
  location      = "EU"
  project       = var.project-id
  force_destroy = true

  uniform_bucket_level_access = true

  cors {
    method          = ["GET", "HEAD", "PUT", "POST"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket_object" "install-scripts" {
  name          = "avml_instance_scripts/${var.installation_script}"
  content        = local.startup_install_dependencies_script
  bucket        = "${google_storage_bucket.demo-avml-bucket.name}"
}

resource "google_storage_bucket_object" "volatility-scripts" {
  name          = "avml_instance_scripts/${var.volatility_script}"
  content        = local.volatility_script
  bucket        = "${google_storage_bucket.demo-avml-bucket.name}"
}


# Define local files for startup scripts
locals {
  startup_avml_instance_script = "${file("${path.module}/instance_startup_scripts/startup_avml_instance.sh")}"
  startup_install_dependencies_script = "${file("${path.module}/instance_startup_scripts/install_dependencies.sh")}"
  volatility_script = "${file("${path.module}/instance_startup_scripts/volatility_commands.sh")}"
}

# Create rendered script template with variable to be used by startup script for instance_mirroring_target
data "template_file" "avml_startup_script" {
  template = local.startup_avml_instance_script
  vars = {
    BUCKET_NAME = "${google_storage_bucket.demo-avml-bucket.name}"
    INSTALLATION_PATH = var.installation_path
    INSTALLATION_SCRIPT = var.installation_script
    INSTALLATION_SCRIPT_BUCKET_PATH = var.installation_script_bucket_path
    INSTALLATION_USER = var.installation_user
    VOLATILITY_SCRIPT = var.volatility_script
  }
}
# Create rendered script template for the script that installs dependencies
data "template_file" "avml_install_dependencies" {
  template = local.startup_install_dependencies_script
  vars = {
    INSTALLATION_PATH = var.installation_path
  }
}
################################################################################################
# Configure outputs
################################################################################################
# Output rendered script
#output "avml_startup_script_rendered" {
#  value = "${data.template_file.avml_startup_script.rendered}"
#}
# Output rendered script
#output "avml_install_dependencies_rendered" {
#  value = "${data.template_file.avml_install_dependencies.rendered}"
#}

output "gcp_project" {
  value = var.project-id
}

output "zone" {
  value = var.zone
}

output "region" {
  value = var.region
}

output "gcp_instance" {
  value = google_compute_instance.avml-instance.name
}

output "gcp_instance_avml_sa" {
  value = google_service_account.tf-avml-sa.email
}

output "gcp_avml_bucket" {
  value = google_storage_bucket.demo-avml-bucket.name
}

output "volatility_script" {
  value = var.volatility_script
}


output "target_project" {
  value = var.project-id
}

# output "gcp_memory_user_to_add_permissions" {
#   value = var.GCP_MEM_USER
# }