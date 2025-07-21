resource "azurerm_container_group" "flyway" {
  name                = "${var.repo_name}-${var.app_env}-flyway"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_ids          = [azapi_resource.container_instance_subnet.id]
  priority            = "Regular"
  dns_config {
    nameservers = [data.azurerm_virtual_network.main.dns_servers[0]]
  }
  diagnostics {
    log_analytics {
      workspace_id  = azurerm_log_analytics_workspace.main.workspace_id
      workspace_key = azurerm_log_analytics_workspace.main.primary_shared_key
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
      FLYWAY_USER            = var.postgresql_admin_username
      FLYWAY_PASSWORD        = var.db_master_password
      FLYWAY_URL             = "jdbc:postgresql://${azurerm_postgresql_flexible_server.postgresql.fqdn}:5432/${var.database_name}"
      FORCE_REDEPLOY         = null_resource.trigger_flyway.id
    }
  }
  ip_address_type = "None" # No public IP for Flyway
  os_type         = "Linux"
  restart_policy  = "OnFailure"

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags,
      ip_address_type
    ]
    replace_triggered_by = [null_resource.trigger_flyway]
  }
  provisioner "local-exec" {
    command     = <<EOT
            TIMEOUT=300
            INTERVAL=10
            ELAPSED=0
            while [ $ELAPSED -lt $TIMEOUT ]; do
                STATUS=$(az container show --resource-group ${var.resource_group_name} --name ${azurerm_container_group.flyway.name} --query "containers[0].instanceView.currentState.exitCode" -o tsv)
                if [ "$STATUS" != "None" ] && [ -n "$STATUS" ]; then
                    break
                fi
                sleep $INTERVAL
                ELAPSED=$((ELAPSED + INTERVAL))
            done

            if [ "$STATUS" != "0" ]; then
                echo "Flyway container failed with exit code $STATUS"
                exit 1
            fi
        EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "trigger_flyway" {
  triggers = {
    always_run = timestamp()
  }
}

