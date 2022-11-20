module "service_account" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "4.1.1"

  project_id = var.project_id

  names = ["velero"]
}

module "custom_role" {
  source  = "terraform-google-modules/iam/google//modules/custom_role_iam"
  version = "7.4.1"

  target_level = "project"
  target_id    = var.project_id
  role_id      = "velero"
  title        = title("velero")
  description  = format("Role for %s", "velero")
  base_roles   = []

  permissions = [
    "compute.disks.get",
    "compute.disks.create",
    "compute.disks.createSnapshot",
    "compute.snapshots.get",
    "compute.snapshots.create",
    "compute.snapshots.useReadOnly",
    "compute.snapshots.delete",
    "compute.zones.get",
    "cloudkms.cryptoKeyVersions.useToDecrypt",
    "cloudkms.cryptoKeyVersions.useToEncrypt",
    "cloudkms.locations.get",
    "cloudkms.locations.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "resourcemanager.projects.get"
  ]

  excluded_permissions = []

  members = [
    format("serviceAccount:%s", module.service_account.email)
  ]

  depends_on = [
    module.service_account
  ]
}

module "iam_service_accounts" {
  count   = var.enable_velero_backups ? 1 : 0
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.4.1"

  project = var.project_id
  mode    = "authoritative"

  service_accounts = [
    module.service_account.email
  ]

  bindings = {
    "roles/iam.workloadIdentityUser" = [
      format("serviceAccount:%s.svc.id.goog[%s/%s]", var.project_id, "storage", "velero")
    ]
  }

  depends_on = [
    module.service_account
  ]
}

module "bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "3.4.0"

  name          = "cloudcauldron-backups"
  project_id    = var.project_id
  location      = "EU"
  storage_class = "MULTI_REGIONAL"
  versioning    = false
  lifecycle_rules = [{
    action = {
      type = "Delete"
    }
    condition = {
      age        = 7
      with_state = "ANY"
    }
  }]

}

module "iam_storage_buckets" {
  source  = "terraform-google-modules/iam/google//modules/storage_buckets_iam"
  version = "7.4.1"

  storage_buckets = [module.bucket.bucket.name]
  mode            = "authoritative"

  bindings = {
    "roles/storage.objectAdmin" = [
      format("serviceAccount:%s", module.service_account.email)
    ]
  }

  depends_on = [
    module.service_account
  ]
}

data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "2.2.1"

  #prevent_destroy = false

  project_id     = var.project_id
  location       = "europe"
  keyring        = "velero"
  keys           = ["velero"]
  set_owners_for = ["velero"]
  owners         = [format("serviceAccount:%s", module.service_account.email)]

  encrypters = [
    data.google_storage_project_service_account.gcs_account.email_address
  ]
  decrypters = [
    data.google_storage_project_service_account.gcs_account.email_address
  ]

}

