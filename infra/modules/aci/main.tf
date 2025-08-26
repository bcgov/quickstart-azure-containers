resource "azurerm_container_group" "busybox" {
  name                = "${var.app_name}-aci"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_ids          = [var.container_instance_subnet_id]
  priority            = "Regular"

  dns_config {
    nameservers = var.dns_servers
  }
  diagnostics {
    log_analytics {
      workspace_id  = var.log_analytics_workspace_id
      workspace_key = var.log_analytics_workspace_key
    }
  }
  container {
    commands = ["sh", "-c", "tail -f /dev/null"]
    name     = "aci-tooling"
    image    = "nicolaka/netshoot:latest"

    cpu    = "1"
    memory = "1"

    environment_variables = {
    }
  }
  ip_address_type = "None"
  os_type         = "Linux"
  restart_policy  = "OnFailure"
  tags            = var.common_tags
  lifecycle {
    ignore_changes = [tags, ip_address_type]
  }

}

