variable "region" {}

variable "zone" {}

variable "project-id" {}

# variable "GCP_MEM_USER" {
#    type        = string
#    description = "This is the user that we'll add the needed roles for - like Service Account Token Creator."
# }

variable "new_service_account_name" {
   type        = string
   description = "New service account name."
   default = "tf-avml-sa"
}

variable "vpc" {
   type        = string
   description = "GCP project VPC."
   default = "default"
}

variable "base_image" {
   type        = string
   description = "Base image for compute engines."
   default = "debian-cloud/debian-12"
}

variable "disk_size" {
   type         = string
   description  = "Base image for compute engines."
   default      = "500"
}

variable "machine_type" {
   type        = string
   description = "Base image for compute engines."
   default = "e2-standard-8"
}

variable "installation_script" {
   type        = string
   description = "Installation dependency script name."
   default = "install_dependencies.sh"
}

variable "installation_script_bucket_path" {
   type        = string
   description = "The path to where installation scripts are stored in the."
   default = "avml_instance_scripts"
}

variable "installation_path" {
   type        = string
   description = "The path to where installation scripts are stored on the instace."
   default = "/root"
}

variable "installation_user" {
   type        = string
   description = "The user for which the installation scripts are run."
   default = "root"
}

variable "volatility_script" {
   type        = string
   description = "The installation script name."
   default = "volatility_commands.sh"
}
