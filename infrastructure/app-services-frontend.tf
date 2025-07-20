
# App Service Plan for frontend application
resource "azurerm_service_plan" "frontend" {
  name                = "${var.app_name}-frontend-asp"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku_name_frontend

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}
# App Service for Frontend with container
resource "azurerm_linux_web_app" "frontend" {
  name                = "${var.repo_name}-${var.app_env}-frontend"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.frontend.id

  # VNet integration for secure communication - same subnet as API
  virtual_network_subnet_id = data.azurerm_subnet.app_service.id

  # Enable HTTPS only
  https_only = true

  # Enable managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_service_identity.id]
  }

  site_config {
    always_on                                     = true
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.app_service_identity.client_id

    # Security - Use latest TLS version
    minimum_tls_version = "1.3"

    # Health check configuration
    health_check_path                 = "/"
    health_check_eviction_time_in_min = 2

    # Application stack for container
    application_stack {
      docker_image_name   = var.frontend_image
      docker_registry_url = "https://ghcr.io"
    }

    # Configure for container deployment
    ftps_state = "Disabled"

    # CORS configuration for frontend
    cors {
      allowed_origins     = ["*"] # Allow all origins for frontend
      support_credentials = false
    }
    ip_restriction {
      service_tag               = "AzureFrontDoor.Backend"
      ip_address                = null
      virtual_network_subnet_id = null
      action                    = "Allow"
      priority                  = 100
      headers {
        x_azure_fdid      = [azurerm_cdn_frontdoor_profile.frontend_frontdoor.resource_guid]
        x_fd_health_probe = []
        x_forwarded_for   = []
        x_forwarded_host  = []
      }
      name = "Allow traffic from Front Door"
    }
    ip_restriction_default_action = "Deny"
    ip_restriction {
      name        = "DenyAll"
      action      = "Deny"
      priority    = 500
      ip_address  = "0.0.0.0/0"
      description = "Deny all other traffic"
    }
  }

  # Application settings for frontend
  app_settings = {
    PORT                                    = "80"
    "WEBSITES_PORT"                         = "3000"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = "false"
    "DOCKER_ENABLE_CI"                      = "true"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key

    # Backend URL for frontend to communicate with API
    "VITE_BACKEND_URL" = "https://${var.repo_name}-${var.app_env}-api.azurewebsites.net"
    "LOG_LEVEL"        = "info" # Default log level for frontend
  }

  # Logs configuration
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
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "frontend_diagnostics" {
  name                       = "${var.app_name}-frontend-diagnostics"
  target_resource_id         = azurerm_linux_web_app.frontend.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

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
