resource "random_password" "postgres_master_password" {
  length  = 16
  special = true
}
# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgresql" {
  name                = "${var.app_name}-postgresql"
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login    = var.postgresql_admin_username
  administrator_password = random_password.postgres_master_password.result

  sku_name              = var.postgresql_sku_name
  version               = var.postgres_version
  zone                  = var.zone
  storage_mb            = var.postgresql_storage_mb
  backup_retention_days = var.backup_retention_period

  geo_redundant_backup_enabled = var.enable_geo_redundant_backup

  # Not allowed to be public in Azure Landing Zone
  # Public network access is disabled to comply with Azure Landing Zone security requirements
  public_network_access_enabled = false

  # High availability configuration
  # when enabled, the standby server will be created in the specified availability zone
  # and compute charges for standby will be added
  dynamic "high_availability" {
    for_each = var.enable_ha ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = var.standby_availability_zone
    }
  }

  # Auto-scaling configuration  
  auto_grow_enabled = var.enable_auto_grow
  tags              = var.common_tags

  # Lifecycle block to handle automatic DNS zone associations by Azure Policy
  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  dynamic "maintenance_window" {
    for_each = var.enable_maintenance_window ? [1] : []
    content {
      day_of_week  = var.maintenance_day_of_week
      start_hour   = var.maintenance_start_hour
      start_minute = var.maintenance_start_minute
    }
  }
}

# Create database
resource "azurerm_postgresql_flexible_server_database" "postgres_database" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Private Endpoint for PostgreSQL Flexible Server
# Note: DNS zone association will be automatically managed by Azure Policy
resource "azurerm_private_endpoint" "postgresql" {
  name                = "${var.app_name}-postgresql-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.app_name}-postgresql-psc"
    private_connection_resource_id = azurerm_postgresql_flexible_server.postgresql.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  tags = var.common_tags

  # Lifecycle block to ignore DNS zone group changes managed by Azure Policy
  lifecycle {
    ignore_changes = [
      private_dns_zone_group,
      tags
    ]
  }
}

# Note: PostgreSQL Flexible Server private endpoint is created above
# Private DNS Zone association is automatically managed by Azure Landing Zone Policy
# The Landing Zone automation will automatically associate the private endpoint 
# with the appropriate managed DNS zone (privatelink.postgres.database.azure.com)

# Time delay to ensure PostgreSQL server is fully ready before configuration changes
resource "time_sleep" "wait_for_postgresql" {
  depends_on = [
    azurerm_postgresql_flexible_server.postgresql,
    azurerm_postgresql_flexible_server_database.postgres_database,
    azurerm_private_endpoint.postgresql
  ]
  create_duration = "60s"
}

# PostgreSQL Configuration for performance
# These configurations require the server to be fully operational
resource "azurerm_postgresql_flexible_server_configuration" "shared_preload_libraries" {
  name      = "shared_preload_libraries"
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  value     = "pg_stat_statements"

  depends_on = [time_sleep.wait_for_postgresql]
}

resource "azurerm_postgresql_flexible_server_configuration" "log_statement" {
  name      = "log_statement"
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  value     = var.enable_server_logs ? var.log_statement_mode : "none"

  depends_on = [
    time_sleep.wait_for_postgresql,
    azurerm_postgresql_flexible_server_configuration.shared_preload_libraries
  ]
}

# Additional logging related configurations (conditional)
resource "azurerm_postgresql_flexible_server_configuration" "log_connections" {
  count     = var.enable_server_logs ? 1 : 0
  name      = "log_connections"
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  value     = "ON"

  depends_on = [time_sleep.wait_for_postgresql]
}

resource "azurerm_postgresql_flexible_server_configuration" "log_disconnections" {
  count     = var.enable_server_logs ? 1 : 0
  name      = "log_disconnections"
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  value     = "ON"

  depends_on = [time_sleep.wait_for_postgresql]
}

resource "azurerm_postgresql_flexible_server_configuration" "log_duration" {
  count     = var.enable_server_logs ? 1 : 0
  name      = "log_duration"
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  value     = "ON"

  depends_on = [time_sleep.wait_for_postgresql]
}

# Slow query logging threshold
resource "azurerm_postgresql_flexible_server_configuration" "log_min_duration_statement" {
  name      = "log_min_duration_statement"
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  value     = tostring(var.log_min_duration_statement_ms)

  depends_on = [time_sleep.wait_for_postgresql]
}

# IO timing tracking
resource "azurerm_postgresql_flexible_server_configuration" "track_io_timing" {
  name      = "track_io_timing"
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  value     = var.track_io_timing ? "ON" : "OFF"

  depends_on = [time_sleep.wait_for_postgresql]
}

# pg_stat_statements.max
resource "azurerm_postgresql_flexible_server_configuration" "pg_stat_statements_max" {
  name      = "pg_stat_statements.max"
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  value     = tostring(var.pg_stat_statements_max)

  depends_on = [
    time_sleep.wait_for_postgresql,
    azurerm_postgresql_flexible_server_configuration.shared_preload_libraries
  ]
}

# Send diagnostics to Log Analytics (metrics & logs) if enabled
resource "azurerm_monitor_diagnostic_setting" "postgres_diagnostics" {
  count                      = var.enable_diagnostic_insights ? 1 : 0
  name                       = "${var.app_name}-postgres-diagnostics"
  target_resource_id         = azurerm_postgresql_flexible_server.postgresql.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  lifecycle {
    precondition {
      condition     = var.enable_diagnostic_insights ? (var.log_analytics_workspace_id != "") : true
      error_message = "Diagnostics enabled but log_analytics_workspace_id is empty. Provide a workspace id."
    }
  }

  dynamic "enabled_log" {
    for_each = var.diagnostic_log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = var.diagnostic_metric_categories
    content {
      category = enabled_metric.value
    }
  }

  depends_on = [time_sleep.wait_for_postgresql]
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
  scopes                   = [azurerm_postgresql_flexible_server.postgresql.id]
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

  depends_on = [azurerm_postgresql_flexible_server.postgresql]
}

# Enable PostGIS extension
resource "azurerm_postgresql_flexible_server_configuration" "azure_extensions" {
  count     = var.enable_is_postgis ? 1 : 0
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  value     = "POSTGIS"

  depends_on = [
    time_sleep.wait_for_postgresql,
    azurerm_postgresql_flexible_server_configuration.shared_preload_libraries
  ]
}

