####################################################
# Define local resources
####################################################
resource "google_compute_instance" "avml-instance" {
  name         = "avml-instance"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project-id

  tags = ["demo-access-rule"]

  boot_disk {
    initialize_params {
      image = var.base_image
      size  = var.disk_size
    }
  }

  network_interface {
    network = var.vpc

    #We'll use cloud NAT for the installation. See the network.tf declaraton.
    #If you want a public IP, use below
    access_config {
    #  // Assigns an ephemeral public IP
    }
  }

  metadata_startup_script = "${data.template_file.avml_startup_script.rendered}" # This should be the output from the rendered template in main.tf

  # If you need to allow your instance to have GCP API rights, reference a service account with those permissions below.
  service_account {
    email  = "${google_service_account.tf-avml-sa.email}"
    scopes = ["cloud-platform"]
  }
}


resource "google_compute_firewall" "allow_iap_ssh" {
  name          = "allow-ssh-iap"
  project       = var.project-id
  network       = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }


  source_ranges = ["35.235.240.0/20"]
}
