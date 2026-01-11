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



variable "enable_aci" {
  description = "Whether to enable the ACI toolbox"
  type        = bool
  default     = false
}

variable "enable_acr" {
  description = "Whether to create an Azure Container Registry (ACR) using the AVM module."
  type        = bool
  default     = false
}

variable "acr_name" {
  description = "ACR name (5-50 lowercase alphanumeric). Required when enable_acr=true."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_acr || can(regex("^[a-z0-9]{5,50}$", var.acr_name))
    error_message = "When enable_acr=true, acr_name must be 5-50 characters, lowercase alphanumeric only (a-z, 0-9)."
  }
}

variable "acr_sku" {
  description = <<-EOT
  ACR SKU (Basic, Standard, Premium).

  Pricing/feature guidance:
  - Basic: lowest cost, best for dev/test and light usage.
  - Standard: higher throughput/limits than Basic for many production workloads.
  - Premium: required for Private Link/private endpoints.

  Official pricing: https://azure.microsoft.com/en-us/pricing/details/container-registry/#pricing
  EOT
  type        = string
  default     = "Basic"
}

variable "acr_public_network_access_enabled" {
  description = <<-EOT
  Whether public access is permitted for the ACR.

  Note (BC Gov Azure Landing Zone): public ACR and Basic SKU are allowed.
  If you need private connectivity (Private Link/private endpoints), keep public access disabled and use Premium.
  EOT
  type        = bool
  default     = true
}

variable "acr_enable_private_endpoint" {
  description = "Whether to create a private endpoint (Private Link) for the ACR. Premium is required when enabled."
  type        = bool
  default     = false
}
variable "acr_admin_enabled" {
  description = "Whether the admin user is enabled for the ACR."
  type        = bool
  default     = false
}

variable "acr_enable_telemetry" {
  description = "Controls whether AVM telemetry is enabled for the ACR module."
  type        = bool
  default     = false
}
variable "enable_app_service_frontend" {
  description = "Whether to enable the App Service frontend"
  type        = bool
  default     = true
  validation {
    # Valid when at least one ingress option is enabled.
    condition     = var.enable_frontdoor || var.enable_app_service_frontend
    error_message = "At least one of Frontdoor or App Service Frontend must be enabled."
  }
}
variable "enable_app_service_backend" {
  description = "Whether to enable the App Service backend"
  type        = bool
  default     = true
  validation {
    # Valid when at least one backend hosting option is enabled.
    condition     = var.enable_container_apps || var.enable_app_service_backend
    error_message = "At least one of App Service Backend or Container Apps must be enabled."
  }
}
variable "enable_database_migrations_aci" {
  description = "Whether to enable the ACI for database migrations using Flyway"
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

# Container Apps Configuration
variable "enable_container_apps" {
  description = "Enable Azure Container Apps alongside App Service"
  type        = bool
  default     = true
}

variable "container_apps_cpu" {
  description = "CPU allocation for Container Apps (in cores)"
  type        = number
  default     = 0.25
}

variable "container_apps_memory" {
  description = "Memory allocation for Container Apps"
  type        = string
  default     = ".5Gi"
}

variable "container_apps_min_replicas" {
  description = "Minimum number of replicas for Container Apps"
  type        = number
  default     = 0
}

variable "container_apps_max_replicas" {
  description = "Maximum number of replicas for Container Apps"
  type        = number
  default     = 3
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
  default     = "18"
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

# -------------
# API Management Variables
# -------------

variable "enable_apim" {
  description = "Whether to enable API Management service"
  type        = bool
  default     = true
}

variable "apim_publisher_name" {
  description = "The name of the publisher/company for APIM"
  type        = string
  default     = "BC Government"
}

variable "apim_publisher_email" {
  description = "The email address of the publisher/company for APIM"
  type        = string
  default     = "no-reply@gov.bc.ca"
}

variable "apim_sku_name" {
  description = "The SKU of the API Management service"
  type        = string
  default     = "StandardV2_1" # this one or "PremiumV2" works in landing zone. `_1 ` is the capacity.
}


variable "apim_enable_diagnostic_settings" {
  description = "Whether to enable diagnostic settings for the API Management service"
  type        = bool
  default     = true
}

variable "apim_enable_application_insights_logger" {
  description = "Whether to enable Application Insights logger for the API Management service"
  type        = bool
  default     = true
}


variable "enable_azure_proxy" {
  description = "Whether to enable Proxy in Azure which allows tunneling to postgres db or other services on Azure from local system."
  type        = bool
  default     = false
}

variable "app_service_sku_name_azure_proxy" {
  description = "The SKU name for the azure proxy App Service plan."
  type        = string
  nullable    = true
}

variable "azure_proxy_image" {
  description = "The image for the Azure Proxy container"
  type        = string
  nullable    = true
}
variable "prevent_rg_deletion_if_contains_resources" {
  description = "AzureRM provider feature flag: refuse to delete a resource group if Azure reports it still contains resources. Set false to allow RG deletion even when Azure-managed/auto-created resources remain (e.g., App Insights Smart Detector rules)."
  type        = bool
  default     = true
}
