resource "azurerm_container_group" "flyway" {
  name                = "${var.repo_name}-${var.app_env}-flyway"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_ids          = [azapi_resource.container_instance_subnet.id]
  diagnostics {
    log_analytics {
      workspace_id = azurerm_log_analytics_workspace.main.id
      workspace_key = azurerm_log_analytics_workspace.main.primary_shared_key
      log_type = "ContainerInstanceLogs"
    }
  }
  container {
    name   = "flyway"
    image  = var.flyway_image
    cpu    = "1"
    memory = "1.5"

    environment_variables = {
      FLYWAY_DEFAULT_SCHEMA  = "app"
      FLYWAY_CONNECT_RETRIES = "10"
      FLYWAY_GROUP           = "true"
    }
    secure_environment_variables = {
      FLYWAY_USER            = var.postgresql_admin_username
      FLYWAY_PASSWORD        = var.db_master_password
      FLYWAY_URL             = "jdbc:postgresql://${azurerm_postgresql_flexible_server.postgresql.fqdn}/${var.database_name}?sslmode=require"
    }

  }
  os_type        = "Linux"
  restart_policy = "OnFailure"

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}
