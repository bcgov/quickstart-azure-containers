# ========================================================================================================
# Terraform Variables for All Environments -- Only static values should go here for all specific tfvars
# NO SECRETS OR SENSITIVE VALUES SHOULD BE STORED IN THESE FILES
# ========================================================================================================

# -----------------------------------------------------------------------------
# Container Apps Configuration (optional alongside App Service) - Backend Only
# -----------------------------------------------------------------------------
enable_container_apps       = false   # Set to true to deploy Container Apps alongside App Service
container_apps_cpu          = 0.25    # CPU cores per container (lower for Consumption)
container_apps_memory       = "0.5Gi" # Memory per container (lower for Consumption)
container_apps_min_replicas = 0       # Minimum replicas (0 for scale-to-zero)
container_apps_max_replicas = 10      # Maximum replicas (higher for Consumption bursting)

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
database_name                        = "app"
postgres_version                     = "18"
postgres_sku_name                    = "B_Standard_B1ms" # Basic tier for dev (GP_Standard_D2s_v3 for prod)
postgres_storage_mb                  = 32768             # 32GB storage
postgres_zone                        = "1"
enable_postgres_auto_grow            = true
postgres_backup_retention_period     = 7
enable_postgres_geo_redundant_backup = false # Set to true for production
enable_postgres_ha                   = false # Set to true for production
enable_postgres_is_postgis           = false # Set to true if you need PostGIS
postgres_standby_availability_zone   = "1"



# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------
log_analytics_sku            = "PerGB2018"
log_analytics_retention_days = 30

# -----------------------------------------------------------------------------
# Feature Flags
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# API Management Configuration
# -----------------------------------------------------------------------------
enable_apim                             = false # Set to true to enable API Management
apim_enable_diagnostic_settings         = true  # Enable diagnostic logging
apim_enable_application_insights_logger = true  # Enable App Insights integration


# -----------------------------------------------------------------------------
# Front Door Configuration
# -----------------------------------------------------------------------------
frontdoor_sku_name = "Standard_AzureFrontDoor" # Standard_AzureFrontDoor or Premium_AzureFrontDoor
enable_frontdoor = false
enable_azure_db_proxy = false
app_service_sku_name_azure_db_proxy="B1"