module "azure_proxy_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "1.0.0"

  name                   = "${var.app_name}-azure-proxy-asp"
  resource_group_name    = var.resource_group_name
  location               = var.location
  os_type                = "Linux"
  sku_name               = var.app_service_sku_name_azure_proxy
  worker_count           = var.app_service_plan_worker_count
  zone_balancing_enabled = false
  tags                   = var.common_tags

  enable_telemetry = var.enable_telemetry
}

resource "random_password" "proxy_chisel_password" {
  length  = 32
  special = false
}
resource "random_string" "proxy_dns_suffix" {
  length  = 24
  special = false
  upper   = false
}
module "azure_proxy_site" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.19.1"

  kind                     = "webapp"
  name                     = "${var.app_name}-${var.app_env}-azure-proxy"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  os_type                  = "Linux"
  service_plan_resource_id = module.azure_proxy_plan.resource_id

  https_only                = true
  virtual_network_subnet_id = var.app_service_subnet_id

  managed_identities = {
    system_assigned = true
  }

  site_config = {
    always_on                               = true
    container_registry_use_managed_identity = true
    minimum_tls_version                     = "1.3"
    health_check_path                       = "/healthz"
    health_check_eviction_time_in_min       = 2
    ftps_state                              = "Disabled"
    websockets_enabled                      = true
    ip_restriction_default_action           = "Allow"

    application_stack = {
      default = {
        docker_image_name   = var.azure_proxy_image
        docker_registry_url = var.container_registry_url
      }
    }

    cors = {
      default = {
        allowed_origins     = ["*"]
        support_credentials = false
      }
    }
  }

  app_settings = {
    PORT                                  = "80"
    WEBSITES_PORT                         = "80"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE   = "false"
    DOCKER_ENABLE_CI                      = "true"
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.appinsights_connection_string
    APPINSIGHTS_INSTRUMENTATIONKEY        = var.appinsights_instrumentation_key
    CHISEL_AUTH                           = "tunnel:${random_password.proxy_chisel_password.result}"
  }

  logs = {
    default = {
      detailed_error_messages = true
      failed_request_tracing  = true
      application_logs = {
        default = {
          file_system_level = "Off"
        }
      }
      http_logs = {
        default = {
          file_system = {
            retention_in_days = 7
            retention_in_mb   = 100
          }
        }
      }
    }
  }

  # Keep plans stable: explicitly set Application Insights tags to an empty map.
  # Without this, some provider/API combinations report an out-of-band change
  # where tags appear as `{}` (empty) even though the configuration was `null`.
  application_insights = {
    tags = {}
  }

  tags             = var.common_tags
  enable_telemetry = var.enable_telemetry
}
resource "azurerm_monitor_diagnostic_setting" "azure_proxy_diagnostics" {
  name                       = "${var.app_name}-azure-proxy-diagnostics"
  target_resource_id         = module.azure_proxy_site.resource_id
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
