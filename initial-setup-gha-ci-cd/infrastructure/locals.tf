locals {
  virtual_network_id = format("/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/virtualNetworks/%s",
    data.azurerm_subscription.current.subscription_id, var.virtual_network_resource_group, var.virtual_network_name
  )
}

locals {
  # NOTE: This can only be a Resource Group name (ie. to create a new Resource Group).
  # The Azure Container App Environment does not support the use of an existing Resource Group, it needs to create its own, and will use this name.
  container_app_infrastructure_resource_group_name = "${var.resource_group_name}_container_app_infra"
}
