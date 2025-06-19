resource "azapi_resource" "github_runners_container_app_subnet" {
  type = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"

  name      = var.container_app_subnet_name
  parent_id = data.azurerm_virtual_network.vnet.id
  locks = [
    data.azurerm_virtual_network.vnet.id
  ]

  body = {
    properties = {
      addressPrefix         = var.container_app_subnet_address_prefix
      defaultOutboundAccess = false
      delegations = [
        {
          name = "GitHubRunnersContainerApp"
          properties = {
            serviceName = "Microsoft.App/environments"
          }
        }
      ]
      networkSecurityGroup = {
        id = azurerm_network_security_group.github_runners_container_app.id
      }
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "github_runners_container_instance_subnet" {
  type = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"

  name      = var.container_instance_subnet_name
  parent_id = data.azurerm_virtual_network.vnet.id
  locks = [
    data.azurerm_virtual_network.vnet.id
  ]

  body = {
    properties = {
      addressPrefix         = var.container_instance_subnet_address_prefix
      defaultOutboundAccess = false
      delegations = [
        {
          name = "GitHubRunnersContainerInstance"
          properties = {
            serviceName = "Microsoft.ContainerInstance/containerGroups"
          }
        }
      ]
      networkSecurityGroup = {
        id = azurerm_network_security_group.github_runners_container_instance.id
      }
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "github_runners_private_endpoint_subnet" {
  type = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"

  name      = var.private_endpoint_subnet_name
  parent_id = data.azurerm_virtual_network.vnet.id
  locks = [
    data.azurerm_virtual_network.vnet.id
  ]

  body = {
    properties = {
      addressPrefix         = var.private_endpoint_subnet_address_prefix
      defaultOutboundAccess = false
      networkSecurityGroup = {
        id = azurerm_network_security_group.github_runners_private_endpoint.id
      }
    }
  }
  response_export_values = ["*"]
}
