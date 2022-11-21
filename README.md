
# Mastogon in GKE @ Google Cloud

This code will setup a VPC network, a GKE cluster, and optionally, a Cloud SQL Postgres instance and the pieces needed to run Velero backups.

To run this, you of course need Terraform installed, along with gcloud.  Everything should be configured to connect with your Google Cloud Services. Where you save state is your own concern, but it's perfectly fine to keep it local if you alone are working on it.

I tend to run these first to get logged in.  Set your passwords, regions, and Google project id in the terraform.tfvars and you're good to go.
```
gcloud auth application-default login
gcloud auth login
```

I'm running an autoscaling Mastodon cluster on all of this but the IAC is still a little rough and ready. So you'll want to tweak things a bit.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 4.43.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bucket"></a> [bucket](#module\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 3.4.0 |
| <a name="module_custom_role"></a> [custom\_role](#module\_custom\_role) | terraform-google-modules/iam/google//modules/custom_role_iam | 7.4.1 |
| <a name="module_gke"></a> [gke](#module\_gke) | terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster | 23.3.0 |
| <a name="module_iam_service_accounts"></a> [iam\_service\_accounts](#module\_iam\_service\_accounts) | terraform-google-modules/iam/google//modules/service_accounts_iam | 7.4.1 |
| <a name="module_iam_storage_buckets"></a> [iam\_storage\_buckets](#module\_iam\_storage\_buckets) | terraform-google-modules/iam/google//modules/storage_buckets_iam | 7.4.1 |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-google-modules/kms/google | 2.2.1 |
| <a name="module_service_account"></a> [service\_account](#module\_service\_account) | terraform-google-modules/service-accounts/google | 4.1.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-google-modules/network/google | 5.2.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_address.cloud_nat_ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_firewall.fw_iap](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_project_metadata.enable_compute_oslogin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_project_metadata) | resource |
| [google_compute_router.cloud_router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.cloud_nat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_sql_database_instance.mastodon_db](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_storage_project_service_account.gcs_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/storage_project_service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_sql"></a> [enable\_sql](#input\_enable\_sql) | Enable Cloud SQL - Postgres  Infrastructure | `bool` | `false` | no |
| <a name="input_enable_velero_backups"></a> [enable\_velero\_backups](#input\_enable\_velero\_backups) | Enable Velero Backups Infrastructure | `bool` | `false` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region | `string` | n/a | yes |
| <a name="input_sql_disk_size"></a> [sql\_disk\_size](#input\_sql\_disk\_size) | The initial postgres disk size | `string` | `"10"` | no |
| <a name="input_sql_root_password"></a> [sql\_root\_password](#input\_sql\_root\_password) | The initial postgres password | `string` | n/a | yes |
| <a name="input_sql_tier"></a> [sql\_tier](#input\_sql\_tier) | The SQL Instance tier | `string` | n/a | yes |

## Netorking - vpc.tf

This sets up the VPC and everything needed to egress to the internet. You can retain my networking settings below - or tweak it for your own.  The trick is just to make sure nothing overlaps.

## The Google Kubernetes Engine cluster - gke.tf

This creates the GKE cluster. A zonal cluster would be cheaper, but I created this for resiliency so it's regional.  It's nodes are entirely private, they autoscale, and it only uses spot nodes that can come and go at will.  Tweak it as you like.

## Cloud SQL - optional - sql.tf

This sets up a Postgres 14 instance.  Be sure to set its root (postgres) password in settings.tfvars - and don't check that back into Git if you clone this repo. Honestly I'd recommend secret protection.

## Velero Backups - optional - velero.tf

You may or may not want this.  GKE **does** provide their own backup system but Velero is cross-platoform, open source, and generally more flexible.  Once you've run this, you still need to create a certificate in KMS, export it to a file, and use that to install the pod/service/etc.   If you want to disable it just delete the file - or - move it to velero.tf.off.  I hope to convert it to a module at some point to avoid all of that.

Install the Velero Client on your laptop/desktop/macbook etc, ensure you're logged into GCP and your kubectl works, and that you've create your KMS certificate,  then run it like so:
```
velero install \
    --provider gcp \
    --plugins velero/velero-plugin-for-gcp:v1.5.2 \
    --bucket cloudcauldron-backups \
    --secret-file ./credentials-velero
```

## Settings - setttings.tfvars

Change what you want in here. As mentioned above, change your database root password.

## Bonus!  The Helm instructions

I've included an example Helm override file.  It's heavily redacted as the thing currently contains secrets.

* Ensure you can connect to your new GKE cluster with "kubectl" and therefore Helm
* Check out the Mastodon source from [here](https://github.com/mastodon/mastodon).
* Go to the "chart" folder.  Then run this:
```
helm install mastodon . -n mastodon --create-namespace -f values-override.yaml
```

Subsequent deployments or changes are run via:
```
helm upgrade mastodon . -f values-override.yaml
```

## Bugs

There's a bug in the gke node pool module where it keeps wanting to reset this:
```
      ~ autoscaling {
          - location_policy      = "ANY" -> null
            # (4 unchanged attributes hidden)
        }
```
They've fixed the module and it should be resolved in the next release of the module.
