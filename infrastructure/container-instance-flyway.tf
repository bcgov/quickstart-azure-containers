resource "azurerm_container_group" "flyway" {
  name                = "${var.repo_name}-${var.app_env}-flyway"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_ids          = [azapi_resource.container_instance_subnet.id]
  container {
    name   = "flyway"
    image     = "${var.flyway_image}"
    cpu    = "1"
    memory = "1.5"

    environment_variables = [
      {
        name  = "FLYWAY_URL"
        value = "jdbc:postgresql://${azurerm_postgresql_flexible_server.postgresql.fqdn}/${var.database_name}?sslmode=require"
      },
      {
        name  = "FLYWAY_USER"
        value = "${var.postgresql_admin_username}"
      },
      {
        name  = "FLYWAY_PASSWORD"
        value = "${var.db_master_password}"
      },
      {
        name  = "FLYWAY_DEFAULT_SCHEMA"
        value = "app"
      },
      {
        name  = "FLYWAY_CONNECT_RETRIES"
        value = "2"
      },
      {
        name  = "FLYWAY_GROUP"
        value = "true"
      }
    ]

  }
  os_type = "Linux"
  restart_policy = "OnFailure"

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}
