#################################################################################
#################################################################################
provider "kubernetes" {
  config_path    = "~/.kube/config"
}
resource "kubernetes_pod" "dumpit_pod" {
metadata {
  name = "dumpit-pod"
  namespace = "default"
}
spec {
  container {
    name  = "dumpit-container"
    image = "gcr.io/${var.project-id}/dumpit_image:latest"
    security_context {
        privileged = "true"
        capabilities {
          add = ["CAP_NET_ADMIN", "CAP_SYS_ADMIN"]
        }
      }
    }
  }
}

#################################################################################
resource "kubernetes_pod" "avml_pod" {
metadata {
  name = "avml-pod"
  namespace = "default"
}
spec {
  container {
    name  = "avml-container"
    image = "gcr.io/${var.project-id}/avml_image:latest"
    security_context {
        privileged = "true"
        capabilities {
          add = ["CAP_NET_ADMIN", "CAP_SYS_ADMIN"]
        }
      }
    }
   restart_policy = "Always" 
  }
}

#################################################################################
resource "kubernetes_pod" "priv_pod_pid" {
metadata {
  name = "priv-pod-pid"
  namespace = "default"
}
spec {
  host_pid = true
  host_network = true
  container {
    name  = "priv-container"
    image = "gcr.io/${var.project-id}/priv_image"
    #command = ["nsenter", "--mount=proc/1/ns/mnt","--","/bin/bash"]
    command = ["/bin/sh", "-c", "sleep 999d"]
    stdin = true
    tty = true
    image_pull_policy = "Always"
    security_context {
        privileged = "true"
        capabilities {
          add = ["CAP_NET_ADMIN", "CAP_SYS_ADMIN"]
        }
      }
    }
  }
}