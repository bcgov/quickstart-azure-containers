resource "azurerm_cdn_frontdoor_profile" "frontend_frontdoor" {
  name                = "${var.app_name}-frontend-frontdoor"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "frontend_firewall_policy" {
  name                = "${replace(var.app_name, "/[^a-zA-Z0-9]/", "")}frontendfirewall"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  mode                = "Prevention"

  custom_rule {
    name                           = "RateLimitByIP"
    enabled                        = true
    priority                       = 1
    type                           = "RateLimitRule"
    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 5
    action                         = "Block"
    match_condition {
      match_variable     = "RemoteAddr"
      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["0.0.0.0/0"] # Apply to all IPs
    }

  }
  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}


