# Azure Storage Account for Static Content
resource "azurerm_storage_account" "static_content" {
  name                          = lower(replace("${var.repo_name}${var.app_env}static", "-", ""))
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  access_tier                   = "Hot"
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
  local_user_enabled = false
  tags               = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}

# Storage Container for static files
resource "azurerm_storage_container" "static" {
  name                  = "static"
  storage_account_id    = azurerm_storage_account.static_content.id
  container_access_type = "blob"
}

# Azure Front Door Profile for static content
resource "azurerm_cdn_frontdoor_profile" "static_frontdoor" {
  name                = "${var.repo_name}-${var.app_env}-static-frontdoor"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = var.common_tags
}

# Azure Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "static_fd_endpoint" {
  name                     = "${var.repo_name}-${var.app_env}-static-fd"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.static_frontdoor.id
}

# Azure Front Door Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "static_origin_group" {
  name                     = "${var.repo_name}-${var.app_env}-static-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.static_frontdoor.id
  session_affinity_enabled = false
  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }
}

# Azure Front Door Origin (Storage Account)
resource "azurerm_cdn_frontdoor_origin" "static_storage_origin" {
  name                           = "${var.repo_name}-${var.app_env}-static-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.static_origin_group.id
  enabled                        = true
  host_name                      = azurerm_storage_account.static_content.primary_blob_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_storage_account.static_content.primary_blob_host
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

# Azure Front Door Route
resource "azurerm_cdn_frontdoor_route" "static_route" {
  name                          = "${var.repo_name}-${var.app_env}-static-fd"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.static_fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.static_storage_origin.id]
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "MatchRequest"
  link_to_default_domain        = true
  https_redirect_enabled        = true
}

# Azure WAF Policy
resource "azurerm_cdn_frontdoor_firewall_policy" "static_waf" {
  name                = "${replace(var.app_name, "/[^a-zA-Z0-9]/", "")}staticwaf"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"
  mode                = "Prevention"
  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
    action  = "Block"
  }
  tags = var.common_tags
}

# Associate WAF Policy with Front Door Endpoint
resource "azurerm_cdn_frontdoor_security_policy" "static_fd_waf_policy" {
  name                     = "${var.repo_name}-${var.app_env}-static-fd-waf-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.static_frontdoor.id
  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.static_waf.id
      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.static_fd_endpoint.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}
