resource "random_integer" "google_iam_workload_identity_pool_random_number" {
  min = 1
  max = 50000
}

resource "google_iam_workload_identity_pool" "gke_pool" {
  workload_identity_pool_id = "gke-pool-${random_integer.google_iam_workload_identity_pool_random_number.result}"
  display_name              = "WIF pool for GKE federation"
  description               = "Identity pool use in insecure GKE cluster"
  disabled                  = false
  project                   = var.project-id
}

resource "google_service_account" "bqowner" {
  project = var.project-id
  account_id = "bqowner"
}

# Create custom GSA for GKE
resource "google_service_account" "custom_gke_sa_ai" {
  project = var.project-id
  account_id   = "custom-gke-sa-ai"
  display_name = "custom-gke-sa-ai"
}

# Create custom KSA 
resource "kubernetes_service_account" "custom_ksa_ai" {
  metadata {
    name      = "custom-ksa-ai"
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.custom_gke_sa_ai.email
    }
  }
}

# Setting the workloadIdentityUser role to the custom KSA
resource "google_service_account_iam_member" "workload_identity_role" {
  service_account_id = google_service_account.custom_gke_sa_ai.id
  role    = "roles/iam.workloadIdentityUser"
  member  = "serviceAccount:${var.project-id}.svc.id.goog[default/${kubernetes_service_account.custom_ksa_ai.metadata[0].name}]"
  #member = "serviceAccount:gcp-research-service-agents.svc.id.goog[default/custom-ksa-ai]"
}

# ----------------------------------------------------------------
# Permissions for the Cloud Build Default SA
# ---------------------------------------------------------------


## Push to GKE
resource "google_project_iam_member" "default_cb_sa_gke" {
  project = var.project-id
  role    = "roles/container.developer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

## Store Image in Artifactory
resource "google_project_iam_member" "default_cb_sa_artifactReg" {
  project = var.project-id
  role    = "roles/artifactregistry.createOnPushWriter"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

## View Binary Authorization Attestors
resource "google_project_iam_member" "default_cb_sa_binauthviewer" {
  project = var.project-id
  role    = "roles/binaryauthorization.attestorsViewer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

## Verify Signature from KMS (CB default SA)
resource "google_project_iam_member" "default_cb_sa_kmssignerifier" {
  project = var.project-id
  role    = "roles/cloudkms.signerVerifier"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

## Verify Signature from KMS (default compute SA)
resource "google_project_iam_member" "default_compute_sa_kmssignerifier" {
  project = var.project-id
  role    = "roles/cloudkms.signerVerifier"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

## Write the note occurance to Container Analysis
resource "google_project_iam_member" "default_cb_sa_notewriter" {
  project = var.project-id
  role    = "roles/containeranalysis.notes.attacher"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

## Verify Signature from KMS (default compute SA)
resource "google_project_iam_member" "custom_gke_sa_ai_kmssignerifier" {
  project = var.project-id
  role    = "roles/cloudkms.signerVerifier"
  member  = "serviceAccount:${google_service_account.custom_gke_sa_ai.email}"
}

## Adding artifact reader permissions to deploy pods to the cluster
resource "google_project_iam_member" "custom_gke_sa_ai_artifactregistry" {
  project = var.project-id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.custom_gke_sa_ai.email}"
}

## Adding artifact reader permissions to deploy pods to the cluster
resource "google_project_iam_member" "custom_gke_sa_ai_vertex_ai" {
  project = var.project-id
  role    = "roles/aiplatform.admin"
  member  = "serviceAccount:${google_service_account.custom_gke_sa_ai.email}"
}