terraform {
  backend "gcs" {
    prefix  = "create-mem-pod/terraform/state"
  }
}

