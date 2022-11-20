
# Mastogon in GKE @ Google Cloud

This code will setup a VPC network, a GKE cluster, and optionally, a Cloud SQL Postgres instance and the pieces needed to run Velero backups.

To run this, you of course need Terraform installed, along with gcloud.  Everything should be configured to connect with your Google Cloud Services. Where you save state is your own concern, but it's perfectly fine to keep it local if you alone are working on it.

I tend to run these first to get logged in.  Set your passwords, regions, and Google project id in the terraform.tfvars and you're good to go.
```
gcloud auth application-default login
gcloud auth login
```

I'm running an autoscaling Mastodon cluster on all of this but the IAC is still a little rough and ready. So you'll want to tweak things a bit.

## Netorking - vpc.tf

This sets up the VPC and everything needed to egress to the internet. You can retain my networking settings below - or tweak it for your own.  The trick is just to make sure nothing overlaps.

## The Google Kubernetes Engine cluster - gke.tf

This creates the GKE cluster. A zonal cluster would be cheaper, but I created this for resiliency so it's regional.  It's nodes are entirely private, they autoscale, and it only uses spot nodes that can come and go at will.  Tweak it as you like.

## Cloud SQL - opional - sql.tf

This sets up a Postgres 14 instance.  Be sure to set its root (postgres) password in settings.tfvars - and don't check that back into Git if you clone this repo. Honestly I'd recommend secret protection.

## Velero Backups - opional - velero.tf

You may or may not want this.  GKE **does** provide their own backup system but Velero is cross-platoform, open source, and generally more flexible.  Once you've run this, you still need to create a certificate in KMS, export it to a file, and use that to install the pod/service/etc.   If you want to disable it just delete the file - or - move it to velero.tf.off.  I hope to convert it to a module at some point to avoid all of that.

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

## Bugs

There's a bug in the gke node pool module where it keeps wanting to reset this:
```
      ~ autoscaling {
          - location_policy      = "ANY" -> null
            # (4 unchanged attributes hidden)
        }
```
They've fixed the module and it should be resolved in the next release of the module.
