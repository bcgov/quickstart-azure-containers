# -------------
# Azure API Management Module
# -------------
# This module creates an Azure API Management instance with v2 configuration
# following production-ready best practices for security, monitoring, and scaling

# API Management Service
resource "azurerm_api_management" "main" {
  name                = "${var.app_name}-apim-${var.app_env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  # Security configurations
  public_network_access_enabled = true
  virtual_network_type          = "External"

  virtual_network_configuration {
    subnet_id = var.subnet_id
  }

  # Identity configuration for secure access to other Azure services
  identity {
    type = "SystemAssigned"
  }

  # Developer portal configuration
  dynamic "sign_in" {
    for_each = local.apim_supports_portal_auth ? [1] : []
    content {
      enabled = var.enable_sign_in
    }
  }

  dynamic "sign_up" {
    for_each = local.apim_supports_portal_auth ? [1] : []
    content {
      enabled = var.enable_sign_up
      terms_of_service {
        consent_required = var.terms_of_service.consent_required
        enabled          = var.terms_of_service.enabled
        text             = var.terms_of_service.text
      }
    }
  }

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

# ---------------------------------------------------------------------------
# API Management Diagnostic Settings
# ---------------------------------------------------------------------------
# Conditional (controlled by var.enable_diagnostic_settings).  Log and metric
# categories are variable-driven so callers can tune without editing this
# module.  NOTE: APIM is not deployed by default (enable_apim = false); these
# settings activate automatically when it is provisioned.
#
# ── How to view logs in the Azure Portal ─────────────────────────────────────
# 1. Open the Log Analytics workspace in the Portal.
# 2. Click "Logs" in the left nav (under General).
# 3. Dismiss the query picker and paste any KQL below into the editor.
# 4. Adjust the time range picker (top-right) — ingestion lag is ~2-5 min.
# ---------------------------------------------------------------------------
#
# Defaults:
#
#  GatewayLogs — one entry per API call processed by the APIM gateway:
#                operation, backend URL, HTTP status, latency (total /
#                backend), client IP, and subscription key (masked).
#                Primary source for API traffic analysis, SLA reporting,
#                and per-consumer usage auditing.
#                LAW table: ApiManagementGatewayLogs
#
#    KQL — recent gateway requests:
#      ApiManagementGatewayLogs
#      | project TimeGenerated, OperationId, Method, Url, ResponseCode,
#                BackendResponseCode, TotalTime, BackendTime, CallerIpAddress
#      | order by TimeGenerated desc
#
#    KQL — error rate by operation:
#      ApiManagementGatewayLogs
#      | where ResponseCode >= 400
#      | summarize count() by ResponseCode, OperationId
#      | order by count_ desc
#
#  WebSocketConnectionLogs — lifecycle events for WebSocket connections
#                            proxied through APIM (connect, disconnect,
#                            message counts).  Required if any API uses the
#                            WebSocket passthrough policy.
#                            LAW table: ApiManagementGatewayLogs (same table,
#                            filtered by OperationType == "WebSocket")
#
#    KQL — WebSocket connection events:
#      ApiManagementGatewayLogs
#      | where OperationType == "WebSocket"
#      | project TimeGenerated, OperationId, CallerIpAddress, ResponseCode,
#                TotalTime
#      | order by TimeGenerated desc
#
#    KQL — active WebSocket connections over time:
#      ApiManagementGatewayLogs
#      | where OperationType == "WebSocket"
#      | summarize count() by bin(TimeGenerated, 5m)
#      | order by TimeGenerated desc
#
#  DeveloperPortalAuditLogs — sign-in, sign-up, product subscription, and
#                             API key operations performed in the Developer
#                             Portal.  Use for access control auditing and
#                             compliance evidence under the portal auth rules
#                             configured by var.enable_sign_in / sign_up.
#                             LAW table: ApiManagementGatewayLogs
#
#    KQL — portal authentication events:
#      ApiManagementGatewayLogs
#      | where Category == "DeveloperPortalAuditLogs"
#      | project TimeGenerated, OperationId, CallerIpAddress, ResponseCode
#      | order by TimeGenerated desc
#
#    KQL — portal activity by client IP:
#      ApiManagementGatewayLogs
#      | where Category == "DeveloperPortalAuditLogs"
#      | summarize count() by CallerIpAddress
#      | order by count_ desc
#
#  AllMetrics — gateway request volume, capacity units, duration percentiles,
#               and failed request counts as pre-aggregated time-series;
#               required for metric alert rules and Monitor dashboards.
#
#    KQL — request volume and latency over time:
#      AzureMetrics
#      | where ResourceProvider == "MICROSOFT.APIMANAGEMENT"
#      | where MetricName in ("TotalRequests", "Duration", "FailedRequests")
#      | summarize avg(Average) by MetricName, bin(TimeGenerated, 5m)
#      | order by TimeGenerated desc
#
#    KQL — gateway capacity utilisation:
#      AzureMetrics
#      | where ResourceProvider == "MICROSOFT.APIMANAGEMENT"
#      | where MetricName == "Capacity"
#      | summarize avg(Average) by bin(TimeGenerated, 5m)
#      | order by TimeGenerated desc
resource "azurerm_monitor_diagnostic_setting" "apim" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${azurerm_api_management.main.name}-diagnostics"
  target_resource_id         = azurerm_api_management.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Log categories (default: GatewayLogs, WebSocketConnectionLogs,
  # DeveloperPortalAuditLogs) — cover API traffic, WebSocket sessions, and
  # portal access audit trail.
  dynamic "enabled_log" {
    for_each = var.diagnostic_log_categories
    content {
      category = enabled_log.value
    }
  }

  # Metric categories (default: AllMetrics) — request volume, capacity, latency
  # percentiles, and error rates for alerting and dashboards.
  dynamic "enabled_metric" {
    for_each = var.diagnostic_metric_categories
    content {
      category = enabled_metric.value
    }
  }
}

# Custom Domain Configuration (optional)
resource "azurerm_api_management_custom_domain" "main" {
  count             = var.custom_domain_configuration != null ? 1 : 0
  api_management_id = azurerm_api_management.main.id

  dynamic "gateway" {
    for_each = var.custom_domain_configuration.gateway != null ? [var.custom_domain_configuration.gateway] : []
    content {
      host_name                    = gateway.value.host_name
      certificate                  = gateway.value.certificate
      certificate_password         = gateway.value.certificate_password
      negotiate_client_certificate = gateway.value.negotiate_client_certificate
    }
  }

  dynamic "developer_portal" {
    for_each = var.custom_domain_configuration.developer_portal != null ? [var.custom_domain_configuration.developer_portal] : []
    content {
      host_name                    = developer_portal.value.host_name
      certificate                  = developer_portal.value.certificate
      certificate_password         = developer_portal.value.certificate_password
      negotiate_client_certificate = developer_portal.value.negotiate_client_certificate
    }
  }
}


# Application Insights Logger (for detailed API analytics)
resource "azurerm_api_management_logger" "appinsights" {
  count               = var.enable_application_insights_logger ? 1 : 0
  name                = "appinsights-logger"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name

  application_insights {
    instrumentation_key = var.appinsights_instrumentation_key
  }
}

# Default API Management Policy (optional)
resource "azurerm_api_management_policy" "main" {
  count             = var.global_policy_xml != null ? 1 : 0
  api_management_id = azurerm_api_management.main.id
  xml_content       = var.global_policy_xml
}

# Named Values for configuration (Key-Value pairs)
resource "azurerm_api_management_named_value" "main" {
  for_each            = var.named_values
  name                = each.key
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  display_name        = each.value.display_name
  value               = each.value.value
  secret              = each.value.secret
  tags                = each.value.tags
}

# Backend Services Configuration
resource "azurerm_api_management_backend" "main" {
  for_each            = var.backend_services
  name                = each.key
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  protocol            = each.value.protocol
  url                 = each.value.url
  description         = each.value.description
  title               = each.value.title

  dynamic "credentials" {
    for_each = each.value.credentials != null ? [each.value.credentials] : []
    content {
      certificate = credentials.value.certificate
      query       = credentials.value.query
      header      = credentials.value.header
      authorization {
        scheme    = credentials.value.authorization.scheme
        parameter = credentials.value.authorization.parameter
      }
    }
  }

  dynamic "tls" {
    for_each = each.value.tls != null ? [each.value.tls] : []
    content {
      validate_certificate_chain = tls.value.validate_certificate_chain
      validate_certificate_name  = tls.value.validate_certificate_name
    }
  }
}
