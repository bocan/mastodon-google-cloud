resource "google_sql_database_instance" "mastodon_db" {
  database_version    = "POSTGRES_14"
  name                = "mastodon-db"
  project             = var.project_id
  region              = var.region
  deletion_protection = false
  root_password       = var.sql_root_password


  settings {
    activation_policy = "ALWAYS"
    availability_type = "REGIONAL"

    backup_configuration {
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }

      enabled                        = true
      start_time                     = "03:00"
      transaction_log_retention_days = 7
    }

    disk_autoresize       = true
    disk_autoresize_limit = 0
    disk_size             = var.sql_disk_size
    disk_type             = "PD_SSD"

    insights_config {
      query_insights_enabled = true
      query_string_length    = 4500
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = module.vpc.network_id
    }

    pricing_plan = "PER_USE"
    tier         = var.sql_tier

  }
}

