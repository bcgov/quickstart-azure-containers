# Replaces the Azure/avm-res-containerinstance-containergroup/azurerm module (last pinned at
# 0.2.0), whose newest release still requires "azurerm ~> 4.0" — incompatible with azurerm v5.
# Hand-rolled here so the repo can move to azurerm v5.
#
# `moved` block below preserves state continuity for deployments that used the AVM module.
moved {
  from = module.flyway_container_group.azurerm_container_group.this
  to   = azurerm_container_group.flyway
}

resource "azurerm_container_group" "flyway" {
  name                = "${var.app_name}-flyway"
  location            = var.location
  resource_group_name = var.resource_group_name

  os_type         = "Linux"
  restart_policy  = "OnFailure"
  priority        = "Regular"
  ip_address_type = "Private"

  # Azure can surface `zones = []` on read even when no zones are selected.
  # Setting it explicitly avoids a persistent state drift note between older/newer provider versions.
  zones = []

  subnet_ids = [var.container_instance_subnet_id]

  dns_config {
    nameservers = var.dns_servers
  }

  diagnostics {
    log_analytics {
      workspace_id  = var.log_analytics_workspace_id
      workspace_key = var.log_analytics_workspace_key
    }
  }

  tags = var.common_tags

  container {
    name   = "flyway"
    image  = var.flyway_image
    cpu    = 0.1
    memory = 0.3

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      FLYWAY_DEFAULT_SCHEMA  = "app"
      FLYWAY_CONNECT_RETRIES = "10"
      FLYWAY_GROUP           = "true"
      FLYWAY_USER            = var.postgresql_admin_username
      FLYWAY_URL             = "jdbc:postgresql://${var.postgres_host}:5432/${var.database_name}"
      FORCE_REDEPLOY         = null_resource.trigger_flyway.id
    }

    # Keep secrets in secure env vars so they don't appear in plain-text container config.
    secure_environment_variables = {
      FLYWAY_PASSWORD = var.db_master_password
    }
  }
}

resource "null_resource" "wait_for_flyway_exit_code" {
  triggers = {
    container_group_id = azurerm_container_group.flyway.id
    always_run         = null_resource.trigger_flyway.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
            TIMEOUT=900
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
