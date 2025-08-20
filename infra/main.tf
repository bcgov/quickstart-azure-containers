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
  diagnostic_retention_days     = var.postgres_diagnostic_retention_days
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

module "flyway" {
  source = "./modules/flyway"

  app_name                     = var.app_name
  container_instance_subnet_id = module.network.container_instance_subnet_id
  database_name                = module.postgresql.database_name
  db_master_password           = module.postgresql.db_master_password
  dns_servers                  = module.network.dns_servers
  flyway_image                 = var.flyway_image
  location                     = var.location
  log_analytics_workspace_id   = module.monitoring.log_analytics_workspace_workspaceId
  log_analytics_workspace_key  = module.monitoring.log_analytics_workspace_key
  postgres_host                = module.postgresql.postgres_host
  postgresql_admin_username    = var.postgresql_admin_username
  resource_group_name          = azurerm_resource_group.main.name

  depends_on = [module.postgresql, module.monitoring]
}

module "frontdoor" {
  source              = "./modules/frontdoor"
  count               = var.enable_frontdoor ? 1 : 0
  app_name            = var.app_name
  enable_frontdoor    = var.enable_frontdoor
  common_tags         = var.common_tags
  frontdoor_sku_name  = var.frontdoor_sku_name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_resource_group.main, module.network]
}

module "frontend" {
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

module "backend" {
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
  enable_cloudbeaver                      = var.enable_cloudbeaver
  enable_frontdoor                        = var.enable_frontdoor
  frontend_frontdoor_resource_guid        = var.enable_frontdoor ? module.frontdoor[0].frontdoor_resource_guid : null
  frontend_possible_outbound_ip_addresses = module.frontend.possible_outbound_ip_addresses
  location                                = var.location
  log_analytics_workspace_id              = module.monitoring.log_analytics_workspace_id
  postgres_host                           = module.postgresql.postgres_host
  postgresql_admin_username               = var.postgresql_admin_username
  private_endpoint_subnet_id              = module.network.private_endpoint_subnet_id
  repo_name                               = var.repo_name
  resource_group_name                     = azurerm_resource_group.main.name

  depends_on = [module.frontend, module.flyway]
}
