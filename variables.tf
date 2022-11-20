
variable "project_id" {
  type        = string
  description = "Project ID"
}
variable "region" {
  type        = string
  description = "Region"
}

variable "sql_root_password" {
  type        = string
  description = "The initial postgres password"
}

variable "sql_disk_size" {
  type        = string
  description = "The initial postgres disk size"
  default     = "10"
}

variable "sql_tier" {
  type        = string
  description = "The SQL Instance tier"
}

variable "enable_velero_backups" {
  description = "Enable Velero Backups Infrastructure"
  default     = false
}

variable "enable_sql" {
  description = "Enable Cloud SQL - Postgres  Infrastructure"
  default     = false
}
