# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "app_service_identity" {
  name                = "${var.app_name}-as-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_resource_group.main]
  tags                = var.common_tags
}