# -------------
# Common Variables for Azure Infrastructure
# -------------

variable "api_image" {
  description = "The image for the API container"
  type        = string
}

variable "app_env" {
  description = "Application environment (dev, test, prod)"
  type        = string
}

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "app_service_sku_name_backend" {
  description = "SKU name for the backend App Service Plan"
  type        = string
  default     = "B1" # Basic tier 
}

variable "app_service_sku_name_frontend" {
  description = "SKU name for the frontend App Service Plan"
  type        = string
  default     = "B1" # Basic tier 
}

variable "client_id" {
  description = "Azure client ID for the service principal"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "app"
}


variable "enable_cloudbeaver" {
  description = "Whether to enable the CloudBeaver database management container"
  type        = bool
  default     = true
}

variable "flyway_image" {
  description = "The image for the Flyway container"
  type        = string
}

variable "frontend_image" {
  description = "The image for the Frontend container"
  type        = string
}

variable "enable_frontdoor" {
  description = "Enable Azure Front Door (set false to expose App Service directly)"
  type        = bool
  default     = false
}

variable "frontdoor_sku_name" {
  description = "SKU name for the Front Door"
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Canada Central"
}

variable "log_analytics_retention_days" {
  description = "Number of days to retain data in Log Analytics Workspace"
  type        = number
  default     = 30
}

variable "log_analytics_sku" {
  description = "SKU for Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"
}

variable "postgres_alert_emails" {
  description = "List of email addresses to receive PostgreSQL alerts"
  type        = list(string)
  default     = []
}

variable "enable_postgres_alerts" {
  description = "Enable creation of PostgreSQL metric alerts and action group"
  type        = bool
  default     = false
}

variable "enable_postgres_auto_grow" {
  description = "Enable auto-grow for PostgreSQL Flexible Server storage"
  type        = bool
  default     = true
}

variable "postgres_backup_retention_period" {
  description = "Backup retention period in days for PostgreSQL Flexible Server"
  type        = number
  default     = 7
  validation {
    condition     = var.postgres_backup_retention_period >= 7 && var.postgres_backup_retention_period <= 35
    error_message = "postgres_backup_retention_period must be between 7 and 35 days (Azure Flexible Server limits)."
  }
}

variable "postgres_diagnostic_log_categories" {
  description = "List of PostgreSQL diagnostic log categories to enable"
  type        = list(string)
  default     = ["PostgreSQLLogs"]
}

variable "postgres_diagnostic_metric_categories" {
  description = "List of PostgreSQL diagnostic metric categories to enable"
  type        = list(string)
  default     = ["AllMetrics"]
}

variable "postgres_diagnostic_retention_days" {
  description = "Retention (days) for diagnostics sent via diagnostic setting (0 disables per-setting retention)"
  type        = number
  default     = 7
  validation {
    condition     = var.postgres_diagnostic_retention_days >= 0 && var.postgres_diagnostic_retention_days <= 365
    error_message = "postgres_diagnostic_retention_days must be between 0 and 365."
  }
}

variable "postgres_enable_diagnostic_insights" {
  description = "Enable Azure Monitor diagnostic settings for PostgreSQL server"
  type        = bool
  default     = true
}

variable "postgres_enable_server_logs" {
  description = "Enable detailed PostgreSQL server logs (connections, disconnections, duration, statements)"
  type        = bool
  default     = true
}

variable "enable_postgres_geo_redundant_backup" {
  description = "Enable geo-redundant backup for PostgreSQL Flexible Server"
  type        = bool
  default     = false
}

variable "enable_postgres_ha" {
  description = "Enable high availability for PostgreSQL Flexible Server"
  type        = bool
  default     = false
}

variable "enable_postgres_is_postgis" {
  description = "Enable PostGIS extension for PostgreSQL Flexible Server"
  type        = bool
  default     = false
}

variable "postgres_log_min_duration_statement_ms" {
  description = "Sets log_min_duration_statement in ms (-1 disables; 0 logs all statements)."
  type        = number
  default     = 500
  validation {
    condition     = var.postgres_log_min_duration_statement_ms >= -1
    error_message = "postgres_log_min_duration_statement_ms must be >= -1."
  }
}

variable "postgres_log_statement_mode" {
  description = "Value for log_statement (none | ddl | mod | all). If postgres_enable_server_logs=false this is overridden to none."
  type        = string
  default     = "ddl"
  validation {
    condition     = contains(["none", "ddl", "mod", "all"], var.postgres_log_statement_mode)
    error_message = "postgres_log_statement_mode must be one of: none, ddl, mod, all"
  }
}

variable "postgres_maintenance_day_of_week" {
  description = "Maintenance window day of week (0=Monday .. 6=Sunday)"
  type        = number
  default     = 6
  validation {
    condition     = var.postgres_maintenance_day_of_week >= 0 && var.postgres_maintenance_day_of_week <= 6
    error_message = "postgres_maintenance_day_of_week must be between 0 and 6."
  }
}

variable "postgres_maintenance_start_hour" {
  description = "Maintenance window start hour (0-23 UTC)"
  type        = number
  default     = 3
  validation {
    condition     = var.postgres_maintenance_start_hour >= 0 && var.postgres_maintenance_start_hour <= 23
    error_message = "postgres_maintenance_start_hour must be 0-23."
  }
}

variable "postgres_maintenance_start_minute" {
  description = "Maintenance window start minute (0-59)"
  type        = number
  default     = 0
  validation {
    condition     = var.postgres_maintenance_start_minute >= 0 && var.postgres_maintenance_start_minute <= 59
    error_message = "postgres_maintenance_start_minute must be 0-59."
  }
}

variable "enable_postgres_maintenance_window" {
  description = "Enable a fixed maintenance window for PostgreSQL Flexible Server (controls patching & potentially backup scheduling stability)."
  type        = bool
  default     = false
}

variable "postgres_metric_alerts" {
  description = "Map defining PostgreSQL metric alerts (metric_name, operator, threshold, aggregation, description)"
  type = map(object({
    metric_name = string
    operator    = string
    threshold   = number
    aggregation = string
    description = string
  }))
  default = {
    cpu_percent = {
      metric_name = "cpu_percent"
      operator    = "GreaterThan"
      threshold   = 80
      aggregation = "Average"
      description = "CPU > 80%"
    }
    storage_used = {
      metric_name = "storage_used"
      operator    = "GreaterThan"
      threshold   = 85
      aggregation = "Average"
      description = "Storage used > 85%"
    }
    active_connections = {
      metric_name = "active_connections"
      operator    = "GreaterThan"
      threshold   = 100
      aggregation = "Average"
      description = "Active connections > 100"
    }
  }
}

variable "postgres_pg_stat_statements_max" {
  description = "Value for pg_stat_statements.max (number of statements tracked)."
  type        = number
  default     = 5000
  validation {
    condition     = var.postgres_pg_stat_statements_max >= 100
    error_message = "postgres_pg_stat_statements_max must be >= 100."
  }
}

variable "postgres_sku_name" {
  description = "SKU name for PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms"
  validation {
    condition     = !var.enable_postgres_ha || can(regex("^(GP_|MO_)", var.postgres_sku_name))
    error_message = "High availability requires a General Purpose (GP_) or Memory Optimized (MO_) SKU. Change postgres_sku_name or disable enable_postgres_ha."
  }
}

variable "postgres_standby_availability_zone" {
  description = "Availability zone for standby replica of PostgreSQL Flexible Server"
  type        = string
  default     = "1"
}

variable "postgres_storage_mb" {
  description = "Storage in MB for PostgreSQL Flexible Server"
  type        = number
  default     = 32768
  validation {
    condition     = var.postgres_storage_mb >= 32768 && var.postgres_storage_mb % 1024 == 0
    error_message = "postgres_storage_mb must be >= 32768 and a multiple of 1024."
  }
}

variable "postgres_track_io_timing" {
  description = "Enable track_io_timing (true/false). Minor overhead; useful for performance diagnostics."
  type        = bool
  default     = true
}

variable "postgres_version" {
  description = "Version of PostgreSQL Flexible Server"
  type        = string
  default     = "16"
}

variable "postgres_zone" {
  description = "Availability zone for PostgreSQL server"
  type        = string
  default     = "1"
}

variable "postgresql_admin_username" {
  description = "Administrator username for PostgreSQL server"
  type        = string
  default     = "pgadmin"
}

variable "repo_name" {
  description = "Name of the repository, used for resource naming"
  type        = string
  default     = "quickstart-azure-containers"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  sensitive   = true
}

variable "use_oidc" {
  description = "Use OIDC for authentication"
  type        = bool
  default     = true
}

variable "vnet_address_space" {
  type        = string
  description = "Address space for the virtual network, it is created by platform team"
}

variable "vnet_name" {
  description = "Name of the existing virtual network"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "Resource group name where the virtual network exists"
  type        = string
}
