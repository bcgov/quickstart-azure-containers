module "flyway_container_group" {
  source  = "Azure/avm-res-containerinstance-containergroup/azurerm"
  version = "0.2.0"

  name                = "${var.app_name}-flyway"
  location            = var.location
  resource_group_name = var.resource_group_name

  os_type        = "Linux"
  restart_policy = "OnFailure"
  priority       = "Regular"

  subnet_ids       = [var.container_instance_subnet_id]
  dns_name_servers = var.dns_servers

  diagnostics_log_analytics = {
    workspace_id  = var.log_analytics_workspace_id
    workspace_key = var.log_analytics_workspace_key
  }

  tags = var.common_tags

  containers = {
    flyway = {
      image  = var.flyway_image
      cpu    = 0.1
      memory = 0.3
      ports = [
        {
          port     = 80
          protocol = "TCP"
        }
      ]
      volumes = {}

      environment_variables = {
        FLYWAY_DEFAULT_SCHEMA  = "app"
        FLYWAY_CONNECT_RETRIES = "10"
        FLYWAY_GROUP           = "true"
        FLYWAY_USER            = var.postgresql_admin_username
        FLYWAY_PASSWORD        = var.db_master_password
        FLYWAY_URL             = "jdbc:postgresql://${var.postgres_host}:5432/${var.database_name}"
        FORCE_REDEPLOY         = null_resource.trigger_flyway.id
      }
      secure_environment_variables = {}
      commands                     = null
    }
  }
}

resource "null_resource" "wait_for_flyway_exit_code" {
  triggers = {
    container_group_id = module.flyway_container_group.resource_id
    always_run         = null_resource.trigger_flyway.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
            TIMEOUT=900
            INTERVAL=10
            ELAPSED=0
            while [ $ELAPSED -lt $TIMEOUT ]; do
                STATUS=$(az container show --resource-group ${var.resource_group_name} --name ${module.flyway_container_group.name} --query "containers[0].instanceView.currentState.exitCode" -o tsv)
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
