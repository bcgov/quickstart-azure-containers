# Container Registry (if using private registry) - Landing Zone compliant
resource "azurerm_container_registry" "main" {
  count               = var.create_container_registry ? 1 : 0
  name                = "${replace(var.app_name, "-", "")}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false

  # Azure Landing Zone security requirements
  public_network_access_enabled = false
  tags                          = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}

# Grant App Services access to Container Registry
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.create_container_registry ? 1 : 0
  scope                = azurerm_container_registry.main[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app_service_identity.principal_id
}

# Private endpoint for Container Registry (Landing Zone compliance)
resource "azurerm_private_endpoint" "container_registry" {
  count               = var.create_container_registry ? 1 : 0
  name                = "${var.app_name}-acr-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "${var.app_name}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.main[0].id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags,
      # Ignore private DNS zone group as it's managed by Azure Policy
      private_dns_zone_group
    ]
  }
}