module "gke" {
  source                            = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version                           = "24.0.0"
  project_id                        = var.project_id
  name                              = "gke-mastodon"
  region                            = var.region

  # regional                        = true
  # zones                           = ["${var.region}-a", "${var.region}-b", "${var.region}-c"]
  regional                          = false
  zones                             = ["${var.region}-a"]

  network                           = "mastodon-vpc"
  subnetwork                        = "mastodon-gke-subnet-02"
  ip_range_pods                     = "mastodon-${var.region}-01-gke-01-pods"
  ip_range_services                 = "mastodon-${var.region}-01-gke-01-services"
  http_load_balancing               = false
  network_policy                    = false
  horizontal_pod_autoscaling        = true
  filestore_csi_driver              = false
  kubernetes_version                = "1.25.7-gke.1000"
  create_service_account            = true
  enable_private_endpoint           = false
  enable_private_nodes              = true
  remove_default_node_pool          = true
  release_channel                   = "RAPID"
  dns_cache                         = true
  logging_service                   = "logging.googleapis.com/kubernetes"
  monitoring_service                = "monitoring.googleapis.com/kubernetes"
  disable_legacy_metadata_endpoints = true
  gce_pd_csi_driver                 = true

  # our node pool autoscales so this isn't needed.
  cluster_autoscaling = {
    enabled             = false
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
    max_cpu_cores       = 0
    min_cpu_cores       = 0
    max_memory_gb       = 0
    min_memory_gb       = 0
    gpu_resources       = []
  }

  master_authorized_networks = [{ cidr_block = "0.0.0.0/0", display_name = "mastodon-all" }, ]

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "e2-medium"

      # node_locations   = "${var.region}-a,${var.region}-b,${var.region}-c"
      node_locations   = "${var.region}-a"

      min_count          = 1
      max_count          = 3
      location_policy    = "ANY"
      local_ssd_count    = 0
      spot               = true
      disk_size_gb       = 60
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      initial_node_count = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}
