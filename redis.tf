#module "memstore" {
#  source = "terraform-google-modules/memorystore/google"

#  name = "mastodon-redis"

#  project                 = var.project_id
#  region                  = var.region
#  authorized_network      = "projects/${var.project_id}/global/networks/${module.vpc.network_name}"
#  connect_mode            = "PRIVATE_SERVICE_ACCESS"
#  enable_apis             = true
#  auth_enabled            = true
#  memory_size_gb          = 1
#  transit_encryption_mode = "DISABLED"

#  redis_configs = {
#    maxmemory-policy = "noeviction"
#  }

#  maintenance_policy = {
#    day = "SUNDAY"
#    start_time = {
#      hours   = 03
#      minutes = 0
#      seconds = 0
#      nanos   = 0
#    }
#  }
#}

#output "redis-auth-string" {
#  value = nonsensitive(module.memstore.auth_string)
#}
