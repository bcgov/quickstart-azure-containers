resource "random_password" "postgres_master_password" {
  length  = 16
  special = true
}
module "postgresql" {
  source  = "Azure/avm-res-dbforpostgresql-flexibleserver/azurerm"
  version = "0.1.4"

  name                = "${var.app_name}-postgresql"
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login    = var.postgresql_admin_username
  administrator_password = random_password.postgres_master_password.result

  sku_name                     = var.postgresql_sku_name
  server_version               = var.postgres_version
  zone                         = var.zone
  storage_mb                   = var.postgresql_storage_mb
  backup_retention_days        = var.backup_retention_period
  geo_redundant_backup_enabled = var.enable_geo_redundant_backup

  public_network_access_enabled = false
  auto_grow_enabled             = var.enable_auto_grow
  tags                          = var.common_tags

  high_availability = var.enable_ha ? {
    mode                      = "ZoneRedundant"
    standby_availability_zone = var.standby_availability_zone
  } : null

  maintenance_window = var.enable_maintenance_window ? {
    day_of_week  = tostring(var.maintenance_day_of_week)
    start_hour   = var.maintenance_start_hour
    start_minute = var.maintenance_start_minute
  } : null

  databases = {
    default = {
      name      = var.database_name
      charset   = "utf8"
      collation = "en_US.utf8"
    }
  }

  private_endpoints_manage_dns_zone_group = false
  private_endpoints = {
    default = {
      name                            = "${var.app_name}-postgresql-pe"
      subnet_resource_id              = var.private_endpoint_subnet_id
      private_service_connection_name = "${var.app_name}-postgresql-psc"
      private_dns_zone_resource_ids   = []
      tags                            = var.common_tags
    }
  }

  server_configuration = local.server_configuration
  diagnostic_settings  = local.diagnostic_settings

  enable_telemetry = var.enable_telemetry
}

# PostgreSQL Alerts & Action Group (conditional)
resource "azurerm_monitor_action_group" "postgres" {
  count               = var.enable_postgres_alerts && length(var.postgres_alert_emails) > 0 ? 1 : 0
  name                = "${var.app_name}-pg-ag"
  resource_group_name = var.resource_group_name
  short_name          = "pgag"

  dynamic "email_receiver" {
    for_each = var.postgres_alert_emails
    content {
      name          = replace(email_receiver.value, "@", "_")
      email_address = email_receiver.value
    }
  }
  tags = var.common_tags
}

resource "azurerm_monitor_metric_alert" "postgres" {
  for_each                 = var.enable_postgres_alerts ? var.postgres_metric_alerts : {}
  name                     = "${var.app_name}-pg-${each.key}"
  resource_group_name      = var.resource_group_name
  scopes                   = [module.postgresql.resource_id]
  description              = each.value.description
  severity                 = 3
  frequency                = "PT5M"
  window_size              = "PT5M"
  auto_mitigate            = true
  target_resource_type     = "Microsoft.DBforPostgreSQL/flexibleServers"
  target_resource_location = var.location

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  dynamic "action" {
    for_each = var.enable_postgres_alerts && length(var.postgres_alert_emails) > 0 ? [1] : []
    content {
      action_group_id = azurerm_monitor_action_group.postgres[0].id
    }
  }

  depends_on = [module.postgresql]
}
