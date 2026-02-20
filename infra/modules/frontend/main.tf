module "frontend_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "1.0.0"

  name                   = "${var.app_name}-frontend-asp"
  resource_group_name    = var.resource_group_name
  location               = var.location
  os_type                = "Linux"
  sku_name               = var.app_service_sku_name_frontend
  worker_count           = var.app_service_plan_worker_count
  zone_balancing_enabled = false
  tags                   = var.common_tags

  enable_telemetry = var.enable_telemetry
}

module "frontend_site" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.20.0"

  kind                     = "webapp"
  name                     = "${var.repo_name}-${var.app_env}-frontend"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  os_type                  = "Linux"
  service_plan_resource_id = module.frontend_plan.resource_id

  https_only                = true
  virtual_network_subnet_id = var.frontend_subnet_id

  managed_identities = {
    system_assigned = true
  }

  site_config = {
    always_on                               = true
    container_registry_use_managed_identity = true
    minimum_tls_version                     = "1.3"
    health_check_path                       = "/"
    health_check_eviction_time_in_min       = 2
    ftps_state                              = "Disabled"

    ip_restriction_default_action = var.enable_frontdoor ? "Deny" : "Allow"
    ip_restriction                = local.frontend_ip_restrictions

    application_stack = {
      default = {
        docker_image_name   = var.frontend_image
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
    WEBSITES_PORT                         = "3000"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE   = "false"
    DOCKER_ENABLE_CI                      = "true"
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.appinsights_connection_string
    APPINSIGHTS_INSTRUMENTATIONKEY        = var.appinsights_instrumentation_key
    VITE_BACKEND_URL                      = coalesce(var.backend_url, "https://${var.repo_name}-${var.app_env}-api.azurewebsites.net")
    LOG_LEVEL                             = "info"
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

  # Azure may automatically add a hidden-link tag to connect the Web App to Application Insights.
  # If we don't model it, Terraform will see it as out-of-band drift and may try to remove it.
  # The value is normalized to lowercase to match what Azure commonly returns.
  tags = merge(
    var.common_tags,
    var.appinsights_resource_id == null ? {} : { "hidden-link:/app-insights-resource-id" = lower(var.appinsights_resource_id) }
  )
  enable_telemetry = var.enable_telemetry
}

# ---------------------------------------------------------------------------
# Frontend App Service Diagnostic Settings
# ---------------------------------------------------------------------------
# Routes all App Service log categories and platform metrics to Log Analytics.
#
#  AppServiceHTTPLogs      — IIS/HTTP access logs: every inbound request with
#                            HTTP status, latency, bytes transferred.  Use for
#                            traffic pattern analysis, CDN cache-miss debugging,
#                            and SLA reporting.
#
#  AppServiceConsoleLogs   — stdout/stderr from the Caddy/frontend container.
#                            Captures reverse-proxy errors, TLS handshake issues,
#                            and Vite/Node startup failures.
#
#  AppServiceAppLogs       — structured application logs written through App
#                            Service log sink (severity-filtered).
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
resource "azurerm_monitor_diagnostic_setting" "frontend_diagnostics" {
  name                       = "${var.app_name}-frontend-diagnostics"
  target_resource_id         = module.frontend_site.resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Per-request HTTP access log (latency, status code, bytes).
  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  # Container stdout/stderr — Caddy reverse-proxy and startup error logs.
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
  host_name                      = module.frontend_site.resource_uri
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = module.frontend_site.resource_uri
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
