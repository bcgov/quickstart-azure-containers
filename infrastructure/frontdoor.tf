resource "azurerm_cdn_frontdoor_profile" "frontend_frontdoor" {
  name                = "${var.app_name}-frontend-frontdoor"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "frontend_fd_endpoint" {
  name                     = "${var.repo_name}-${var.app_env}-frontend-fd"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontend_frontdoor.id
}

resource "azurerm_cdn_frontdoor_origin_group" "frontend_origin_group" {
  name                     = "${var.repo_name}-${var.app_env}-frontend-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontend_frontdoor.id
  session_affinity_enabled = true

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

}
resource "azurerm_cdn_frontdoor_origin" "frontend_app_service_origin" {
  name                          = "${var.repo_name}-${var.app_env}-frontend-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontend_origin_group.id

  enabled                        = true
  host_name                      = azurerm_linux_web_app.frontend.default_hostname
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_linux_web_app.frontend.default_hostname
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "frontend_route" {
  name                          = "${var.repo_name}-${var.app_env}-frontend-fd"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.frontend_fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontend_origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.frontend_app_service_origin.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled = false
  }
}