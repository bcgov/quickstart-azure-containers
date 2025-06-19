data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}
data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = var.existing_vnet_resource_group_name
}