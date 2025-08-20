
# App Service Plan for frontend application
resource "azurerm_service_plan" "frontend" {
  name                = "${var.app_name}-frontend-asp"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku_name_frontend
  tags                = var.common_tags
  lifecycle {
    ignore_changes = [tags]
  }
}

# App Service for Frontend with container
resource "azurerm_linux_web_app" "frontend" {
  name                      = "${var.repo_name}-${var.app_env}-frontend"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  service_plan_id           = azurerm_service_plan.frontend.id
  virtual_network_subnet_id = var.frontend_subnet_id
  https_only                = true
  identity {
    type = "SystemAssigned"
  }
  site_config {
    always_on                               = true
    container_registry_use_managed_identity = true
    minimum_tls_version                     = "1.3"
    health_check_path                       = "/"
    health_check_eviction_time_in_min       = 2
    application_stack {
      docker_image_name   = var.frontend_image
      docker_registry_url = var.container_registry_url
    }
    ftps_state = "Disabled"
    cors {
      allowed_origins     = ["*"]
      support_credentials = false
    }
    dynamic "ip_restriction" {
      for_each = var.enable_frontdoor ? [1] : []
      content {
        service_tag               = "AzureFrontDoor.Backend"
        ip_address                = null
        virtual_network_subnet_id = null
        action                    = "Allow"
        priority                  = 100
        headers {
          x_azure_fdid      = [var.frontend_frontdoor_resource_guid]
          x_fd_health_probe = []
          x_forwarded_for   = []
          x_forwarded_host  = []
        }
        name = "Allow traffic from Front Door"
      }
    }
    # If Front Door disabled, allow all (could refine with IP restrictions as needed)
    dynamic "ip_restriction" {
      for_each = var.enable_frontdoor ? [] : [1]
      content {
        name                      = "AllowAll"
        action                    = "Allow"
        priority                  = 100
        ip_address                = "0.0.0.0/0"
        virtual_network_subnet_id = null
      }
    }
    ip_restriction_default_action = var.enable_frontdoor ? "Deny" : "Allow"
  }
  app_settings = {
    PORT                                  = "80"
    WEBSITES_PORT                         = "3000"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE   = "false"
    DOCKER_ENABLE_CI                      = "true"
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.appinsights_connection_string
    APPINSIGHTS_INSTRUMENTATIONKEY        = var.appinsights_instrumentation_key
    VITE_BACKEND_URL                      = "https://${var.repo_name}-${var.app_env}-api.azurewebsites.net"
    LOG_LEVEL                             = "info"
  }
  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 100
      }
    }
  }
  tags = var.common_tags
  lifecycle {
    ignore_changes = [tags]
  }

}

# Frontend Diagnostics
resource "azurerm_monitor_diagnostic_setting" "frontend_diagnostics" {
  name                       = "${var.app_name}-frontend-diagnostics"
  target_resource_id         = azurerm_linux_web_app.frontend.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enabled_log {
    category = "AppServiceHTTPLogs"
  }
  enabled_log {
    category = "AppServiceConsoleLogs"
  }
  enabled_log {
    category = "AppServiceAppLogs"
  }
  enabled_log {
    category = "AppServicePlatformLogs"
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "frontend_fd_endpoint" {
  count                    = var.enable_frontdoor ? 1 : 0
  name                     = "${var.repo_name}-${var.app_env}-frontend-fd"
  cdn_frontdoor_profile_id = var.frontend_frontdoor_id
}

resource "azurerm_cdn_frontdoor_origin_group" "frontend_origin_group" {
  count                    = var.enable_frontdoor ? 1 : 0
  name                     = "${var.repo_name}-${var.app_env}-frontend-origin-group"
  cdn_frontdoor_profile_id = var.frontend_frontdoor_id
  session_affinity_enabled = true

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

}

resource "azurerm_cdn_frontdoor_origin" "frontend_app_service_origin" {
  count                         = var.enable_frontdoor ? 1 : 0
  name                          = "${var.repo_name}-${var.app_env}-frontend-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontend_origin_group[0].id

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
  count                         = var.enable_frontdoor ? 1 : 0
  name                          = "${var.repo_name}-${var.app_env}-frontend-fd"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.frontend_fd_endpoint[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontend_origin_group[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.frontend_app_service_origin[0].id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
}
resource "azurerm_cdn_frontdoor_security_policy" "frontend_fd_security_policy" {
  count                    = var.enable_frontdoor ? 1 : 0
  name                     = "${var.app_name}-frontend-fd-waf-security-policy"
  cdn_frontdoor_profile_id = var.frontend_frontdoor_id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = var.frontdoor_frontend_firewall_policy_id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.frontend_fd_endpoint[0].id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}
