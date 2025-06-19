resource "azurerm_network_security_group" "github_runners_container_app" {
  name                = var.container_app_subnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_network_security_group" "github_runners_container_instance" {
  name                = var.container_instance_subnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_network_security_group" "github_runners_private_endpoint" {
  name                = var.private_endpoint_subnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
