resource "google_container_cluster" "insecure_cluster" {
  name     = "insecure-cluster"
  location = var.region
  project  = var.project-id
  #node_version = "1.30.10-gke.1022000"
  #min_master_version = "1.30.10-gke.1022000"

  
############################
#### Node Configuration ####
  remove_default_node_pool = true
  initial_node_count       = 1
  enable_intranode_visibility = true
  enable_shielded_nodes = false
  confidential_nodes {
    enabled = false
  }
    node_config {
    preemptible     = true
    machine_type    = var.compute_engine_type
    }
  node_locations = [
    var.zone
  ]



################################
#### Network Configurations ####

  network = var.vpc

   master_authorized_networks_config {
     cidr_blocks {
       cidr_block = "${jsondecode(data.http.ipinfo.response_body).ip}/32"
       display_name = "myip"
     }
     cidr_blocks {
       cidr_block = "216.17.89.219/32"
       display_name = "Greyduck"
     }
     cidr_blocks {
       cidr_block = "136.226.0.0/16"
       display_name = "Zscaler"
     }
   }
#######################################
#### Binary Authorization Settings ####

## Options are:
## -  "DISABLED: Neither project level policies nor CV policies are considered 
## -  "PROJECT_SINGLETON_POLICY_ENFORCE": Policies defined at the Project-Level are consdiered 
## -  "POLICY_BINDINGS_AND_PROJECT_SINGLETON_POLICY_ENFORCE": Both Project-Level policis (project singleton) and Continuous Validation (platform) policies are considered
## -  "POLICY_BINDING": Only Continuous Validation (platform) policies are considered.
## When Policies Binding mode is specified, you must indicate the full resource name of the CV policies to use.
# binary_authorization {

#       evaluation_mode = "POLICY_BINDING"
#   }



#############################################
### Cluster Master Endpoint Configuration ###

private_cluster_config {
  enable_private_endpoint = false
}


###########################
#### Identity Settings ####
workload_identity_config {
  workload_pool = "${var.project-id}.svc.id.goog"
}

# identity_service_config {
#   enabled = true
# }


###########################
#### Misc Settings ####

  deletion_protection = false
  cost_management_config {
    enabled = true
  }

###########################
#### Misc Integrations ####
# notification_config {
#   pubsub{
#     enabled = false
#     topic = google_pubsub_topic.gke_notifications.id
#   }
# }



################################
#### Logging and Monitoring ####

## Stackdriver Logging and Monitoring
logging_service = "logging.googleapis.com/kubernetes"
monitoring_service = "monitoring.googleapis.com/kubernetes"


################
#### Addons ####
addons_config {
  http_load_balancing {
    disabled = true
  }

  horizontal_pod_autoscaling {
    disabled = true
  }

  gke_backup_agent_config {
    enabled = true
  }
  config_connector_config {
    enabled = false
  }
  network_policy_config {
    disabled = true
  }

  ## Access Cloud Filestore as a Volume in the Cluster
  # https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/filestore-csi-driver
  gcp_filestore_csi_driver_config {
    enabled = true
  }
  ## Access A GCS Bucket as a Volume in the Cluster
  ## https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/cloud-storage-fuse-csi-driver
  gcs_fuse_csi_driver_config {
    enabled = true
  }

}
depends_on = [ google_project_service.enable_project_apis ]

}


 resource "google_container_node_pool" "insecure_gke_node" {
   name       = "insecure-gke-node-pool"
   location   = var.region
   project    = var.project-id
   cluster    = google_container_cluster.insecure_cluster.name
   node_count = 1
   node_config {
    preemptible  = true
    machine_type = var.compute_engine_type
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    service_account = google_service_account.custom_gke_sa_ai.email
     oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
   }
 }
