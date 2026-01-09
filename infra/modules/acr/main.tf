module "acr" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.5.0"

  name                = var.acr_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.common_tags

  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled

  diagnostic_settings = local.diagnostic_settings

  private_endpoints                       = local.private_endpoints
  private_endpoints_manage_dns_zone_group = false

  enable_telemetry = var.enable_telemetry
}
