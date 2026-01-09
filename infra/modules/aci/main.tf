module "aci_tooling" {
  source  = "Azure/avm-res-containerinstance-containergroup/azurerm"
  version = "0.2.0"

  name                = "${var.app_name}-aci"
  location            = var.location
  resource_group_name = var.resource_group_name

  os_type        = "Linux"
  restart_policy = "OnFailure"
  priority       = "Regular"

  subnet_ids       = [var.container_instance_subnet_id]
  dns_name_servers = var.dns_servers
  enable_telemetry = var.enable_telemetry
  tags             = var.common_tags

  diagnostics_log_analytics = {
    workspace_id  = var.log_analytics_workspace_id
    workspace_key = var.log_analytics_workspace_key
  }

  containers = {
    "aci-tooling" = {
      image                        = "nicolaka/netshoot:latest"
      cpu                          = 0.02
      memory                       = 0.1
      ports                        = []
      volumes                      = {}
      environment_variables        = {}
      secure_environment_variables = {}
      commands                     = ["sh", "-c", "tail -f /dev/null"]
    }
  }
}

