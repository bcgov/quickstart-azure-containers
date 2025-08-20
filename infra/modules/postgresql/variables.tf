variable "app_name" {
  description = "Name of the application"
  type        = string
  nullable    = false
}

variable "auto_grow_enabled" {
  description = "Enable auto-grow for storage"
  type        = bool
  nullable    = false
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  nullable    = false
}

variable "maintenance_window_enabled" {
  description = "Enable custom maintenance window"
  type        = bool
  default     = false
}

variable "maintenance_day_of_week" {
  description = "Maintenance window day of week (0=Mon..6=Sun)"
  type        = number
  default     = 6
}

variable "maintenance_start_hour" {
  description = "Maintenance window start hour (0-23 UTC)"
  type        = number
  default     = 3
}

variable "maintenance_start_minute" {
  description = "Maintenance window start minute (0-59)"
  type        = number
  default     = 0
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  nullable    = false
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  nullable    = false
}


variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup"
  type        = bool
  nullable    = false
}

variable "ha_enabled" {
  description = "Enable high availability"
  type        = bool
  nullable    = false
}

variable "is_postgis_enabled" {
  description = "Enable PostGIS extension for PostgreSQL Flexible Server"
  type        = bool
  nullable    = false
}

variable "enable_server_logs" {
  description = "Enable detailed PostgreSQL server logging (connections, disconnections, duration, statements)"
  type        = bool
  default     = true
}

variable "log_statement_mode" {
  description = "Value for log_statement parameter (none | ddl | mod | all)"
  type        = string
  default     = "ddl"
}

variable "log_min_duration_statement_ms" {
  description = "Value for log_min_duration_statement in ms (-1 disables)"
  type        = number
  default     = 500
}

variable "track_io_timing" {
  description = "Enable track_io_timing (true/false)"
  type        = bool
  default     = true
}

variable "pg_stat_statements_max" {
  description = "pg_stat_statements.max value"
  type        = number
  default     = 5000
}

variable "enable_diagnostic_insights" {
  description = "Enable Azure Monitor diagnostic settings (logs & metrics) for PostgreSQL server"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID to send diagnostics to (required if enable_diagnostic_insights=true)"
  type        = string
  default     = ""
}

variable "diagnostic_log_categories" {
  description = "List of diagnostic log categories to enable for PostgreSQL"
  type        = list(string)
  default     = ["PostgreSQLLogs"]
}

variable "diagnostic_metric_categories" {
  description = "List of diagnostic metric categories to enable for PostgreSQL"
  type        = list(string)
  default     = ["AllMetrics"]
}

variable "diagnostic_retention_days" {
  description = "Retention days for diagnostics (0 disables per-setting retention policy)"
  type        = number
  default     = 0
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  nullable    = false
}

variable "postgres_version" {
  description = "The version of PostgreSQL to use."
  type        = string
  nullable    = false
}

variable "postgresql_admin_username" {
  description = "Administrator username for PostgreSQL server"
  type        = string
  default     = "pgadmin"
}

variable "postgresql_sku_name" {
  description = "SKU name for PostgreSQL Flexible Server"
  type        = string
  nullable    = false
}

variable "postgresql_storage_mb" {
  description = "Storage in MB for PostgreSQL server"
  type        = number
  nullable    = false
}


variable "private_endpoint_subnet_id" {
  description = "The ID of the subnet for the private endpoint."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  nullable    = false
}

variable "standby_availability_zone" {
  description = "Availability zone for standby replica"
  type        = string
  nullable    = false
}

variable "zone" {
  description = "The availability zone for the PostgreSQL Flexible Server."
  type        = string
  nullable    = false
}
variable "postgres_alerts_enabled" {
  description = "Enable creation of PostgreSQL metric alerts and action group"
  type        = bool
  nullable    = false
}

variable "postgres_alert_emails" {
  description = "List of email addresses to receive PostgreSQL alerts"
  type        = list(string)
  nullable    = false
}

variable "postgres_metric_alerts" {
  description = "Map defining PostgreSQL metric alerts (metric_name, operator, threshold, aggregation, description)"
  nullable    = false
  type = map(object({
    metric_name = string
    operator    = string
    threshold   = number
    aggregation = string
    description = string
  }))
}
