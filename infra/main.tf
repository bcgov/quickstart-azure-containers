# -------------
# Root Level Terraform Configuration
# -------------
# Create the main resource group for all application resources
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.common_tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# -------------
# Modules based on Dependency
# -------------
module "network" {
  source = "./modules/network"

  common_tags              = var.common_tags
  resource_group_name      = azurerm_resource_group.main.name
  vnet_address_space       = var.vnet_address_space
  vnet_name                = var.vnet_name
  vnet_resource_group_name = var.vnet_resource_group_name

  depends_on = [azurerm_resource_group.main]
}

module "monitoring" {
  source = "./modules/monitoring"

  app_name                     = var.app_name
  common_tags                  = var.common_tags
  location                     = var.location
  log_analytics_retention_days = var.log_analytics_retention_days
  log_analytics_sku            = var.log_analytics_sku
  resource_group_name          = azurerm_resource_group.main.name

  depends_on = [azurerm_resource_group.main, module.network]
}

module "postgresql" {
  source = "./modules/postgresql"

  app_name                      = var.app_name
  enable_auto_grow              = var.enable_postgres_auto_grow
  backup_retention_period       = var.postgres_backup_retention_period
  common_tags                   = var.common_tags
  database_name                 = var.database_name
  diagnostic_log_categories     = var.postgres_diagnostic_log_categories
  diagnostic_metric_categories  = var.postgres_diagnostic_metric_categories
  enable_diagnostic_insights    = var.postgres_enable_diagnostic_insights
  enable_server_logs            = var.postgres_enable_server_logs
  enable_geo_redundant_backup   = var.enable_postgres_geo_redundant_backup
  enable_ha                     = var.enable_postgres_ha
  enable_is_postgis             = var.enable_postgres_is_postgis
  location                      = var.location
  log_analytics_workspace_id    = module.monitoring.log_analytics_workspace_id
  log_min_duration_statement_ms = var.postgres_log_min_duration_statement_ms
  log_statement_mode            = var.postgres_log_statement_mode
  maintenance_day_of_week       = var.postgres_maintenance_day_of_week
  maintenance_start_hour        = var.postgres_maintenance_start_hour
  maintenance_start_minute      = var.postgres_maintenance_start_minute
  enable_maintenance_window     = var.enable_postgres_maintenance_window
  pg_stat_statements_max        = var.postgres_pg_stat_statements_max
  postgres_version              = var.postgres_version
  postgresql_admin_username     = var.postgresql_admin_username
  postgresql_sku_name           = var.postgres_sku_name
  postgresql_storage_mb         = var.postgres_storage_mb
  postgres_alert_emails         = var.postgres_alert_emails
  enable_postgres_alerts        = var.enable_postgres_alerts
  postgres_metric_alerts        = var.postgres_metric_alerts
  private_endpoint_subnet_id    = module.network.private_endpoint_subnet_id
  resource_group_name           = azurerm_resource_group.main.name
  standby_availability_zone     = var.postgres_standby_availability_zone
  track_io_timing               = var.postgres_track_io_timing
  zone                          = var.postgres_zone

  depends_on = [module.network, module.monitoring]
}


module "frontdoor" {
  source              = "./modules/frontdoor"
  count               = var.enable_frontdoor ? 1 : 0
  app_name            = var.app_name
  common_tags         = var.common_tags
  frontdoor_sku_name  = var.frontdoor_sku_name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_resource_group.main, module.network]
}

module "frontend" {
  count  = var.enable_app_service_frontend ? 1 : 0
  source = "./modules/frontend"

  app_env                               = var.app_env
  app_name                              = var.app_name
  app_service_sku_name_frontend         = var.app_service_sku_name_frontend
  appinsights_connection_string         = module.monitoring.appinsights_connection_string
  appinsights_instrumentation_key       = module.monitoring.appinsights_instrumentation_key
  common_tags                           = var.common_tags
  enable_frontdoor                      = var.enable_frontdoor
  frontend_frontdoor_id                 = var.enable_frontdoor ? module.frontdoor[0].frontdoor_id : null
  frontend_frontdoor_resource_guid      = var.enable_frontdoor ? module.frontdoor[0].frontdoor_resource_guid : null
  frontend_image                        = var.frontend_image
  frontend_subnet_id                    = module.network.app_service_subnet_id
  frontdoor_frontend_firewall_policy_id = var.enable_frontdoor ? module.frontdoor[0].firewall_policy_id : null
  location                              = var.location
  log_analytics_workspace_id            = module.monitoring.log_analytics_workspace_id
  repo_name                             = var.repo_name
  resource_group_name                   = azurerm_resource_group.main.name

  depends_on = [module.monitoring, module.network]
}

module "flyway" {
  count  = var.enable_database_migrations_aci ? 1 : 0
  source = "./modules/flyway"

  app_name                     = var.app_name
  common_tags                  = var.common_tags
  database_name                = var.database_name
  flyway_image                 = var.flyway_image
  location                     = var.location
  container_instance_subnet_id = module.network.container_instance_subnet_id
  log_analytics_workspace_id   = module.monitoring.log_analytics_workspace_workspaceId
  log_analytics_workspace_key  = module.monitoring.log_analytics_workspace_key
  postgres_host                = module.postgresql.postgres_host
  postgresql_admin_username    = var.postgresql_admin_username
  db_master_password           = module.postgresql.db_master_password
  resource_group_name          = azurerm_resource_group.main.name
  dns_servers                  = module.network.dns_servers

  depends_on = [module.network, module.postgresql]
}
module "backend" {
  count  = var.enable_app_service_backend ? 1 : 0
  source = "./modules/backend"

  api_image                               = var.api_image
  app_env                                 = var.app_env
  app_name                                = var.app_name
  app_service_sku_name_backend            = var.app_service_sku_name_backend
  app_service_subnet_id                   = module.network.app_service_subnet_id
  appinsights_connection_string           = module.monitoring.appinsights_connection_string
  appinsights_instrumentation_key         = module.monitoring.appinsights_instrumentation_key
  backend_subnet_id                       = module.network.app_service_subnet_id
  common_tags                             = var.common_tags
  database_name                           = var.database_name
  db_master_password                      = module.postgresql.db_master_password
  enable_frontdoor                        = var.enable_frontdoor
  frontend_frontdoor_resource_guid        = var.enable_frontdoor ? module.frontdoor[0].frontdoor_resource_guid : null
  frontend_possible_outbound_ip_addresses = var.enable_app_service_frontend ? module.frontend[0].possible_outbound_ip_addresses : ""
  location                                = var.location
  log_analytics_workspace_id              = module.monitoring.log_analytics_workspace_id
  postgres_host                           = module.postgresql.postgres_host
  postgresql_admin_username               = var.postgresql_admin_username
  repo_name                               = var.repo_name
  resource_group_name                     = azurerm_resource_group.main.name

  depends_on = [module.frontend]
}

# API Management Module (optional)
module "apim" {
  count  = var.enable_apim ? 1 : 0
  source = "./modules/apim"

  app_name                           = var.app_name
  app_env                            = var.app_env
  location                           = var.location
  resource_group_name                = azurerm_resource_group.main.name
  common_tags                        = var.common_tags
  publisher_name                     = var.apim_publisher_name
  publisher_email                    = var.apim_publisher_email
  sku_name                           = var.apim_sku_name
  subnet_id                          = module.network.apim_subnet_id
  enable_diagnostic_settings         = var.apim_enable_diagnostic_settings
  log_analytics_workspace_id         = module.monitoring.log_analytics_workspace_id
  enable_application_insights_logger = var.apim_enable_application_insights_logger
  appinsights_instrumentation_key    = module.monitoring.appinsights_instrumentation_key

  # Backend services configuration - connect to the deployed backend
  backend_services = {
    "backend-api" = {
      protocol    = "http"
      url         = var.enable_app_service_backend ? "https://${module.backend[0].backend_url}" : var.enable_container_apps ? "http://${module.container_apps[0].backend_container_app_url}" : ""
      description = "Backend API service"
      title       = "Backend API"
    }
  }

  depends_on = [module.network, module.monitoring, module.backend]
}

# Container Apps Module (optional alongside App Service)
module "container_apps" {
  count  = var.enable_container_apps ? 1 : 0
  source = "./modules/container-apps"

  app_name                            = var.app_name
  app_env                             = var.app_env
  location                            = var.location
  resource_group_name                 = azurerm_resource_group.main.name
  common_tags                         = var.common_tags
  container_apps_subnet_id            = module.network.container_apps_subnet_id
  log_analytics_workspace_id          = module.monitoring.log_analytics_workspace_id
  backend_image                       = var.api_image
  database_name                       = var.database_name
  postgres_host                       = module.postgresql.postgres_host
  postgresql_admin_username           = var.postgresql_admin_username
  db_master_password                  = module.postgresql.db_master_password
  appinsights_connection_string       = module.monitoring.appinsights_connection_string
  appinsights_instrumentation_key     = module.monitoring.appinsights_instrumentation_key
  app_service_frontend_url            = var.enable_app_service_frontend && length(module.frontend) > 0 ? module.frontend[0].frontend_url : ""
  container_cpu                       = var.container_apps_cpu
  container_memory                    = var.container_apps_memory
  min_replicas                        = var.container_apps_min_replicas
  max_replicas                        = var.container_apps_max_replicas
  migrations_image                    = var.flyway_image
  private_endpoint_subnet_id          = module.network.private_endpoint_subnet_id
  enable_system_assigned_identity     = true
  log_analytics_workspace_customer_id = module.monitoring.log_analytics_workspace_workspaceId
  log_analytics_workspace_key         = module.monitoring.log_analytics_workspace_key

  depends_on = [module.network, module.monitoring, module.postgresql, module.frontend]
}

module "aci" {
  count  = var.enable_aci ? 1 : 0
  source = "./modules/aci"

  app_name                     = var.app_name
  location                     = var.location
  resource_group_name          = azurerm_resource_group.main.name
  common_tags                  = var.common_tags
  container_instance_subnet_id = module.network.container_instance_subnet_id
  log_analytics_workspace_id   = module.monitoring.log_analytics_workspace_workspaceId
  log_analytics_workspace_key  = module.monitoring.log_analytics_workspace_key
  dns_servers                  = module.network.dns_servers

  depends_on = [module.network, module.monitoring, module.postgresql]
}

module "azure_proxy" {
  source = "./modules/azure-proxy"
  count  = var.enable_azure_proxy ? 1 : 0

  app_env                          = var.app_env
  app_name                         = var.app_name
  app_service_sku_name_azure_proxy = var.app_service_sku_name_azure_proxy
  app_service_subnet_id            = module.network.app_service_subnet_id
  appinsights_connection_string    = module.monitoring.appinsights_connection_string
  appinsights_instrumentation_key  = module.monitoring.appinsights_instrumentation_key
  azure_proxy_image                = var.azure_proxy_image
  common_tags                      = var.common_tags
  location                         = var.location
  log_analytics_workspace_id       = module.monitoring.log_analytics_workspace_id
  repo_name                        = var.repo_name
  resource_group_name              = azurerm_resource_group.main.name

  depends_on = [module.monitoring, module.network]
}
