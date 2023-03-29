provider "google" {
  region = var.region
}

resource "google_compute_project_metadata" "enable_compute_oslogin" {
  project = var.project_id
  metadata = {
    enable-oslogin = "TRUE"
  }
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "5.2.0"

  project_id   = var.project_id
  network_name = "mastodon-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name      = "mastodon-subnet-01"
      subnet_ip        = "10.1.32.0/21"
      subnet_region    = var.region
      subnet_flow_logs = "false"
      description      = "The subnet used for Mastadon Services"
    },
    {
      subnet_name      = "mastodon-gke-subnet-02"
      subnet_ip        = "10.1.24.0/21"
      subnet_region    = var.region
      subnet_flow_logs = "false"
      description      = "The subnet used for Mastadon on GKE"
    }
  ]

  secondary_ranges = {
    mastodon-gke-subnet-02 = [
      {
        range_name    = "mastodon-${var.region}-01-gke-01-pods"
        ip_cidr_range = "10.1.0.0/20"
      },
      {
        range_name    = "mastodon-${var.region}-01-gke-01-services"
        ip_cidr_range = "10.1.16.0/21"
      }
    ]

  }

  routes = [
    {
      name              = "mastodon-egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    }
  ]
}

resource "google_compute_address" "cloud_nat_ip" {
  name        = "mastodon-nat-ip"
  region      = var.region
  project     = var.project_id
  description = "Cloud Nat external IP"
}

resource "google_compute_router" "cloud_router" {
  name    = "mastodon-router"
  region  = var.region
  network = module.vpc.network_id
  project = var.project_id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "cloud_nat" {
  name                               = "mastodon-cloud-nat"
  router                             = google_compute_router.cloud_router.name
  region                             = google_compute_router.cloud_router.region
  project                            = var.project_id
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = ["${google_compute_address.cloud_nat_ip.self_link}"]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "fw_iap" {
  name          = "mastodon-fw-allow-iap-hc"
  project       = var.project_id
  direction     = "INGRESS"
  network       = module.vpc.network_name
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
  allow {
    protocol = "tcp"
  }
}
