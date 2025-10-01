terraform {
  backend "gcs" {
    prefix  = "create-mem-resources/terraform/state"
  }
}

