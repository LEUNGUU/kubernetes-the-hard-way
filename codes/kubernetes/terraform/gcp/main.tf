# networks
resource "google_compute_network" "vnet" {
  name                    = "${var.environment}-vnet"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "container"
  ip_cidr_range = var.address_prefix
  region        = var.region
  network       = google_compute_network.vnet.id
}

resource "google_compute_firewall" "internal" {
  name    = "internal"
  network = google_compute_network.vnet.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }

  source_ranges = var.internal_cidr
}

resource "google_compute_firewall" "external" {
  name    = "external"
  network = google_compute_network.vnet.id

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }
  source_ranges = var.external_cidr
}

resource "google_compute_address" "extip" {
  name   = "external-ip"
  region = var.region
}

# Compute instances (we use instance template here)
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "bastion" {
  name           = "bastion"
  machine_type   = var.vm_size
  zone           = var.zone
  can_ip_forward = true

  network_interface {
    network    = google_compute_network.vnet.self_link
    subnetwork = google_compute_subnetwork.subnet.name
    # we dont have enough quota for external ip address
    access_config {}
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  metadata = {
    sshKeys = "centos:${file("/root/.ssh/id_rsa.pub")}"
  }

  service_account {
    scopes = var.controller_scopes
  }

  # resize VM after initial creation
  allow_stopping_for_update = true

  description = "bastion"

  tags = ["bastion"]

}
resource "google_compute_instance" "controller" {
  count          = var.controller_count
  name           = "${var.environment}-controller-${count.index}"
  machine_type   = var.vm_size
  zone           = var.zone
  can_ip_forward = true

  network_interface {
    network    = google_compute_network.vnet.self_link
    subnetwork = google_compute_subnetwork.subnet.name
    network_ip = element(var.controller_ip_list, count.index)
    # we dont have enough quota for external ip address
    # access_config {}
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  metadata = {
    sshKeys = "centos:${file("/root/.ssh/id_rsa.pub")}"
  }

  service_account {
    scopes = var.controller_scopes
  }

  # resize VM after initial creation
  allow_stopping_for_update = true

  description = "kubernetes Controller Nodes"

  tags = var.controller_node_tags

}

resource "google_compute_instance" "worker" {
  count          = var.worker_count
  name           = "${var.environment}-worker-${count.index}"
  machine_type   = var.vm_size
  zone           = var.zone
  can_ip_forward = true

  network_interface {
    network    = google_compute_network.vnet.self_link
    subnetwork = google_compute_subnetwork.subnet.name
    network_ip = element(var.worker_ip_list, count.index)
    # we dont have enough quota for external ip address
    # access_config {}
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  metadata = {
    pod-cidr = element(var.pod_address_prefix, count.index)
    sshKeys = "centos:${file("/root/.ssh/id_rsa.pub")}"
  }

  service_account {
    scopes = var.worker_scopes
  }

  # resize VM after initial creation
  allow_stopping_for_update = true

  description = "kubernetes Worker Nodes"

  tags = var.worker_node_tags

}

# google external load balancer
resource "google_compute_http_health_check" "health_check" {
  name         = "health-check"
  description  = "Kubernetes Health check"
  host         = "kubernetes.default.svc.cluster.local"
  request_path = "/healthz"

  timeout_sec        = 2
  check_interval_sec = 2
}

resource "google_compute_firewall" "health_check_rules" {
  name    = "allow-health-check"
  network = google_compute_network.vnet.id

  allow {
    protocol = "tcp"
  }

  source_ranges = ["209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16"]
}

resource "google_compute_target_pool" "target" {
  name   = "target-pool"
  region = var.region

  instances = [
    "${var.zone}/${var.environment}-controller-0",
    "${var.zone}/${var.environment}-controller-1",
    "${var.zone}/${var.environment}-controller-2",
  ]

  health_checks = [
    google_compute_http_health_check.health_check.name,
  ]
}

resource "google_compute_forwarding_rule" "forwarding_rules" {
  name       = "kubernetes-forwarding-rules"
  region     = var.region
  ip_address = google_compute_address.extip.address
  target     = google_compute_target_pool.target.id
  port_range = "6443"
}
