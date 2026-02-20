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
  version = "0.20.0"

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

  # Disable AVM-internal Application Insights creation — the monitoring module
  # already provisions App Insights and its LAW.  Connection string & key are
  # passed via app_settings above, so no duplicate resource is needed.
  enable_application_insights = false

  tags             = var.common_tags
  enable_telemetry = var.enable_telemetry
}
# ---------------------------------------------------------------------------
# Azure Proxy App Service Diagnostic Settings
# ---------------------------------------------------------------------------
# Routes all App Service log categories and platform metrics to Log Analytics
# for the chisel/privoxy reverse-proxy tier.
#
# ── How to view logs in the Azure Portal ─────────────────────────────────────
# 1. Open the Log Analytics workspace in the Portal.
# 2. Click "Logs" in the left nav (under General).
# 3. Dismiss the query picker and paste any KQL below into the editor.
# 4. Adjust the time range picker (top-right) — ingestion lag is ~2-5 min.
# ---------------------------------------------------------------------------
#
# Log categories:
#
#  AppServiceHTTPLogs — IIS/HTTP access log: one row per inbound request with
#                       HTTP method, URI, status code, latency (ms), bytes
#                       transferred, and client IP.  Use for auditing which
#                       clients are tunnelling through the proxy and to detect
#                       unexpected traffic volumes.
#
#    KQL — recent requests:
#      AppServiceHTTPLogs
#      | project TimeGenerated, CsHost, CsMethod, CsUriStem, ScStatus,
#                TimeTaken, CIp
#      | order by TimeGenerated desc
#
#    KQL — 4xx/5xx error breakdown by path:
#      AppServiceHTTPLogs
#      | where ScStatus >= 400
#      | summarize count() by ScStatus, CsUriStem
#      | order by count_ desc
#
#  AppServiceConsoleLogs — stdout/stderr from the container process (chisel or
#                          privoxy).  Primary source for connection errors,
#                          authentication failures, and startup diagnostics.
#                          Level is either "Informational" or "Error".
#
#    KQL — recent error output:
#      AppServiceConsoleLogs
#      | where Level == "Error"
#      | project TimeGenerated, Level, Host, ResultDescription, ContainerId
#      | order by TimeGenerated desc
#
#    KQL — log volume by level (5-minute buckets):
#      AppServiceConsoleLogs
#      | summarize count() by Level, bin(TimeGenerated, 5m)
#      | order by TimeGenerated desc
#
#  AppServiceAppLogs — structured application logs written through the App
#                      Service logging SDK (severity-filtered).  Requires SDK
#                      integration in the app; empty if the app writes only to
#                      stdout.  Fields: Level, Message, ExceptionClass, Method,
#                      Stacktrace, Host, ContainerId.
#
#    KQL — application errors and warnings:
#      AppServiceAppLogs
#      | where Level in ("Error", "Warning", "Critical")
#      | project TimeGenerated, Level, Message, ExceptionClass,
#                Method, Stacktrace, Host
#      | order by TimeGenerated desc
#
#    KQL — log count by severity:
#      AppServiceAppLogs
#      | summarize count() by Level
#      | order by count_ desc
#
#  AppServicePlatformLogs — platform lifecycle events: container start/stop,
#                           health-check evictions, deployment slot swaps, and
#                           scaling operations.  OperationName is always
#                           "ContainerLogs"; Level: Informational/Error/Warning.
#
#    KQL — platform errors and warnings:
#      AppServicePlatformLogs
#      | where Level in ("Error", "Warning")
#      | project TimeGenerated, Level, OperationName, Message,
#                ContainerId, Host
#      | order by TimeGenerated desc
#
#    KQL — container restart timeline:
#      AppServicePlatformLogs
#      | where Message contains "starting" or Message contains "stopped"
#      | project TimeGenerated, Level, Message, Host
#      | order by TimeGenerated desc
#
#  AllMetrics — CPU %, memory %, HTTP queue length, and response time sent
#               to Azure Monitor for alerting and capacity planning of the
#               proxy tier.
#
#    KQL — average response time per 5-minute window:
#      AzureMetrics
#      | where ResourceProvider == "MICROSOFT.WEB"
#      | where MetricName == "AverageResponseTime"
#      | summarize avg(Average) by bin(TimeGenerated, 5m)
#      | order by TimeGenerated desc
#
#    KQL — CPU and memory utilisation:
#      AzureMetrics
#      | where ResourceProvider == "MICROSOFT.WEB"
#      | where MetricName in ("CpuTime", "MemoryWorkingSet")
#      | summarize avg(Average) by MetricName, bin(TimeGenerated, 5m)
#      | order by TimeGenerated desc
resource "azurerm_monitor_diagnostic_setting" "azure_proxy_diagnostics" {
  name                       = "${var.app_name}-azure-proxy-diagnostics"
  target_resource_id         = module.azure_proxy_site.resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Per-request HTTP access log (method, URI, status, latency, client IP).
  # KQL: AppServiceHTTPLogs
  #      | project TimeGenerated, CsHost, CsMethod, CsUriStem, ScStatus, TimeTaken, CIp
  #      | order by TimeGenerated desc
  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  # Container stdout/stderr — chisel/privoxy runtime errors and connection logs.
  # KQL: AppServiceConsoleLogs | where Level == "Error"
  #      | project TimeGenerated, Level, Host, ResultDescription, ContainerId
  #      | order by TimeGenerated desc
  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  # SDK-level structured application logs (Level, Message, ExceptionClass, Stacktrace).
  # KQL: AppServiceAppLogs | where Level in ("Error","Warning","Critical")
  #      | project TimeGenerated, Level, Message, ExceptionClass, Method, Stacktrace, Host
  #      | order by TimeGenerated desc
  enabled_log {
    category = "AppServiceAppLogs"
  }

  # Platform events: container restarts, health-check evictions, scaling.
  # KQL: AppServicePlatformLogs | where Level in ("Error","Warning")
  #      | project TimeGenerated, Level, OperationName, Message, ContainerId, Host
  #      | order by TimeGenerated desc
  enabled_log {
    category = "AppServicePlatformLogs"
  }

  # CPU, memory, HTTP queue, and response time metrics.
  # KQL: AzureMetrics | where ResourceProvider == "MICROSOFT.WEB"
  #      | where MetricName in ("CpuTime","MemoryWorkingSet","AverageResponseTime")
  #      | summarize avg(Average) by MetricName, bin(TimeGenerated, 5m)
  enabled_metric {
    category = "AllMetrics"
  }
}
