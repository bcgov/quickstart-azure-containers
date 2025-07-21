variable "postgresql_sku_name" {
  description = "SKU name for PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms" # Basic SKU for development purposes
}

variable "postgresql_storage_mb" {
  description = "Storage in MB for PostgreSQL server"
  type        = number
  default     = 32768
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = false
}

variable "ha_enabled" {
  description = "Enable high availability"
  type        = bool
  default     = false
}

variable "standby_availability_zone" {
  description = "Availability zone for standby replica"
  type        = string
  default     = "2"
}

variable "auto_grow_enabled" {
  description = "Enable auto-grow for storage"
  type        = bool
  default     = true
}
variable "is_postgis_enabled" {
  description = "Enable PostGIS extension for PostgreSQL Flexible Server"
  type        = bool
  default     = false
}
