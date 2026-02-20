

module "backend_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "1.0.0"

  name                   = "${var.app_name}-backend-asp"
  resource_group_name    = var.resource_group_name
  location               = var.location
  os_type                = "Linux"
  sku_name               = var.app_service_sku_name_backend
  worker_count           = var.app_service_plan_worker_count
  zone_balancing_enabled = false
  tags                   = var.common_tags

  enable_telemetry = var.enable_telemetry
}

module "backend_site" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.20.0"

  kind                     = "webapp"
  name                     = "${var.repo_name}-${var.app_env}-api"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  os_type                  = "Linux"
  service_plan_resource_id = module.backend_plan.resource_id

  https_only                = true
  virtual_network_subnet_id = var.backend_subnet_id

  managed_identities = {
    system_assigned = true
  }

  site_config = {
    always_on                               = true
    container_registry_use_managed_identity = true
    minimum_tls_version                     = "1.3"
    health_check_path                       = "/api/health"
    health_check_eviction_time_in_min       = 2
    ftps_state                              = "Disabled"

    ip_restriction_default_action = "Allow"
    ip_restriction                = local.backend_ip_restrictions

    application_stack = {
      default = {
        docker_image_name   = var.api_image
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
    NODE_ENV                              = var.node_env
    PORT                                  = "80"
    DOCKER_ENABLE_CI                      = "true"
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.appinsights_connection_string
    APPINSIGHTS_INSTRUMENTATIONKEY        = var.appinsights_instrumentation_key
    POSTGRES_HOST                         = var.postgres_host
    POSTGRES_USER                         = var.postgresql_admin_username
    POSTGRES_PASSWORD                     = var.db_master_password
    POSTGRES_DATABASE                     = var.database_name
    WEBSITE_SKIP_RUNNING_KUDUAGENT        = "false"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE   = "false"
    WEBSITE_ENABLE_SYNC_UPDATE_SITE       = "1"
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

# Backend Autoscaler
resource "azurerm_monitor_autoscale_setting" "backend_autoscale" {
  name                = "${var.app_name}-backend-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = module.backend_plan.resource_id
  enabled             = var.enable_backend_autoscale
  profile {
    name = "default"
    capacity {
      default = 2
      minimum = 1
      maximum = 10
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = module.backend_plan.resource_id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = module.backend_plan.resource_id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Backend App Service Diagnostic Settings
# ---------------------------------------------------------------------------
# Routes all App Service log categories and platform metrics to Log Analytics.
#
#  AppServiceHTTPLogs      — IIS/HTTP access logs: every inbound request with
#                            HTTP status, latency, bytes transferred.  Use for
#                            traffic pattern analysis and SLA reporting.
#
#  AppServiceConsoleLogs   — stdout/stderr emitted by the container process.
#                            Mirrors what `az webapp log tail` shows; needed for
#                            runtime debugging without SSH access.
#
#  AppServiceAppLogs       — structured application logs written through the
#                            App Service logging SDK (severity-filtered).
#
#  AppServiceAuditLogs     — authentication / Easy Auth sign-in and sign-out
#                            events.  Required for security compliance evidence.
#
#  AppServicePlatformLogs  — platform lifecycle events: container start/stop,
#                            health-check evictions, deployment slot swaps, and
#                            scaling operations.
#
#  AllMetrics              — CPU %, memory %, HTTP queue length, response time,
#                            and request counts sent to Azure Monitor for
#                            alerting and autoscale observability.
resource "azurerm_monitor_diagnostic_setting" "backend_diagnostics" {
  name                       = "${var.app_name}-backend-diagnostics"
  target_resource_id         = module.backend_site.resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Per-request HTTP access log (latency, status code, bytes).
  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  # Container stdout/stderr — primary source for runtime error details.
  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  # SDK-level application log entries (structured, severity-filtered).
  enabled_log {
    category = "AppServiceAppLogs"
  }

  # Easy Auth / authentication audit trail — sign-in/sign-out events.
  enabled_log {
    category = "AppServiceAuditLogs"
  }

  # Platform events: restarts, health-check evictions, scaling, deployments.
  enabled_log {
    category = "AppServicePlatformLogs"
  }

  # CPU, memory, HTTP queue, response time, and request-count metrics.
  enabled_metric {
    category = "AllMetrics"
  }
}
