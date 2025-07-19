# Azure PostgreSQL Flexible Server for Landing Zone compatibility
data "azurerm_client_config" "current" {}

# Data source for existing virtual network
data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

# Data source for private endpoint subnet
data "azurerm_subnet" "private_endpoint" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = var.vnet_resource_group_name
  depends_on           = [azapi_resource.privateendpoints_subnet]
}

# Data source for existing subnet for App Services
data "azurerm_subnet" "app_service" {
  name                 = var.apps_service_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = var.vnet_resource_group_name
  depends_on           = [azapi_resource.app_service_subnet]
}

# Data source for existing web subnet
data "azurerm_subnet" "web" {
  name                 = var.web_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = var.vnet_resource_group_name
  depends_on           = [azapi_resource.web_subnet]
}

# Data souce for container instance subnet
data "azurerm_subnet" "container_instance" {
  name                 = var.container_instance_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = var.vnet_resource_group_name
  depends_on           = [azapi_resource.container_instance_subnet]
}