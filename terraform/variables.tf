variable "region" {}

variable "zone" {}

variable "project-id" {}

variable "vpc" {
   type        = string
   description = "GCP project VPC."
   default = "default"
}


variable "compute_engine_type" {
   type        = string
   description = "Compute engine type for GKE Node"
   default = "e2-standard-8"   
  #  default = "e2-highmem-8"
}


output "region" {
  value = var.region
}

output "zone" {
  value = var.zone
}

output "project-id" {
  value = var.project-id
}


output "my-ip" {
  value = jsondecode(data.http.ipinfo.response_body).ip
}
