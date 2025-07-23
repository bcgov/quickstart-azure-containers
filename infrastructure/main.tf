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
# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "app_service_identity" {
  name                = "${var.app_name}-as-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_resource_group.main]
  tags                = var.common_tags
}

# -------------
# Modules based on Dependency
# -------------
module "networking" {
  source                   = "./modules/networking"
  vnet_resource_group_name = var.vnet_resource_group_name
  common_tags              = var.common_tags
  resource_group_name      = azurerm_resource_group.main.name
  vnet_address_space       = var.vnet_address_space
  vnet_name                = var.vnet_name
  depends_on               = [azurerm_resource_group.main]
}
module "postgresdb" {
  source                       = "./modules/postgresdb"
  resource_group_name          = azurerm_resource_group.main.name
  database_name                = var.database_name
  db_master_password           = var.db_master_password
  app_name                     = var.app_name
  location                     = var.location
  postgresql_admin_username    = var.postgresql_admin_username
  common_tags                  = var.common_tags
  private_endpoint_subnet_id   = module.networking.private_endpoint_subnet_id
  zone                         = var.postgres_zone
  ha_enabled                   = var.postgres_ha_enabled
  backup_retention_period      = var.postgres_backup_retention_period
  postgresql_storage_mb        = var.postgres_storage_mb
  auto_grow_enabled            = var.postgres_auto_grow_enabled
  is_postgis_enabled           = var.postgres_is_postgis_enabled
  standby_availability_zone    = var.postgres_standby_availability_zone
  postgres_version             = var.postgres_version
  postgresql_sku_name          = var.postgres_sku_name
  geo_redundant_backup_enabled = var.postgres_geo_redundant_backup_enabled

  depends_on = [module.networking]
}
module "monitoring" {
  source                       = "./modules/monitoring"
  app_name                     = var.app_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  log_analytics_sku            = var.log_analytics_sku
  log_analytics_retention_days = var.log_analytics_retention_days
  common_tags                  = var.common_tags
  depends_on                   = [azurerm_resource_group.main, module.networking]
}

module "flyway" {
  source   = "./modules/flyway"
  app_name = var.app_name

  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  postgres_host                = module.postgresdb.postgres_host
  postgresql_admin_username    = var.postgresql_admin_username
  db_master_password           = var.db_master_password
  database_name                = module.postgresdb.database_name
  flyway_image                 = var.flyway_image
  log_analytics_workspace_id   = module.monitoring.log_analytics_workspace_workspaceId
  log_analytics_workspace_key  = module.monitoring.log_analytics_workspace_key
  dns_servers                  = module.networking.dns_servers
  container_instance_subnet_id = module.networking.container_instance_subnet_id
  depends_on                   = [module.postgresdb, module.monitoring]
}



module "frontdoor" {
  source              = "./modules/frontdoor"
  app_name            = var.app_name
  resource_group_name = azurerm_resource_group.main.name
  common_tags         = var.common_tags
  frontdoor_sku_name  = var.frontdoor_sku_name
  depends_on          = [azurerm_resource_group.main, module.networking]
}


module "frontend" {
  source                                = "./modules/frontend"
  app_name                              = var.app_name
  repo_name                             = var.repo_name
  app_env                               = var.app_env
  resource_group_name                   = azurerm_resource_group.main.name
  location                              = var.location
  app_service_sku_name_frontend         = var.app_service_sku_name_frontend
  common_tags                           = var.common_tags
  frontend_image                        = var.frontend_image
  user_assigned_identity_id             = azurerm_user_assigned_identity.app_service_identity.id
  user_assigned_identity_client_id      = azurerm_user_assigned_identity.app_service_identity.client_id
  frontend_subnet_id                    = module.networking.app_service_subnet_id
  appinsights_connection_string         = module.monitoring.appinsights_connection_string
  appinsights_instrumentation_key       = module.monitoring.appinsights_instrumentation_key
  log_analytics_workspace_id            = module.monitoring.log_analytics_workspace_id
  frontend_frontdoor_resource_guid      = module.frontdoor.frontdoor_resource_guid
  frontdoor_frontend_firewall_policy_id = module.frontdoor.firewall_policy_id
  frontend_frontdoor_id                 = module.frontdoor.frontdoor_id
  depends_on                            = [module.frontdoor, module.monitoring, module.networking]
}

module "backend" {
  source                                  = "./modules/backend"
  app_name                                = var.app_name
  repo_name                               = var.repo_name
  app_env                                 = var.app_env
  resource_group_name                     = azurerm_resource_group.main.name
  location                                = var.location
  app_service_sku_name_backend            = var.app_service_sku_name_backend
  common_tags                             = var.common_tags
  user_assigned_identity_id               = azurerm_user_assigned_identity.app_service_identity.id
  user_assigned_identity_client_id        = azurerm_user_assigned_identity.app_service_identity.client_id
  backend_subnet_id                       = module.networking.app_service_subnet_id
  appinsights_connection_string           = module.monitoring.appinsights_connection_string
  appinsights_instrumentation_key         = module.monitoring.appinsights_instrumentation_key
  log_analytics_workspace_id              = module.monitoring.log_analytics_workspace_id
  private_endpoint_subnet_id              = module.networking.private_endpoint_subnet_id
  app_service_subnet_id                   = module.networking.app_service_subnet_id
  postgres_host                           = module.postgresdb.postgres_host
  frontend_possible_outbound_ip_addresses = module.frontend.possible_outbound_ip_addresses
  frontend_frontdoor_resource_guid        = module.frontdoor.frontdoor_resource_guid
  database_name                           = var.database_name
  db_master_password                      = var.db_master_password
  postgresql_admin_username               = var.postgresql_admin_username
  api_image                               = var.api_image
  depends_on                              = [module.frontend, module.flyway]
}




