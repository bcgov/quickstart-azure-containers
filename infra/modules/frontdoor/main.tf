resource "azurerm_cdn_frontdoor_profile" "frontend_frontdoor" {
  name                = "${var.app_name}-frontend-frontdoor"
  resource_group_name = var.resource_group_name
  sku_name            = var.frontdoor_sku_name

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}

# ---------------------------------------------------------------------------
# Front Door Profile Diagnostic Settings
# ---------------------------------------------------------------------------
# Sends Front Door telemetry to Log Analytics.
#
# Note: Microsoft.Cdn/profiles (Front Door Standard/Premium) does NOT support
# log_analytics_destination_type = "Dedicated". Azure silently ignores the
# property and always routes to the shared AzureDiagnostics table with
# ResourceProvider == "MICROSOFT.CDN".  Do NOT set destination_type here.
#
# ── How to view logs in the Azure Portal ────────────────────────────────────
# 1. Open the Log Analytics workspace in the Portal.
# 2. Click "Logs" in the left nav (under General).
# 3. Dismiss the query picker and paste any KQL below into the editor.
# 4. Adjust the time range picker (top-right) — ingestion lag is ~2-5 min.
#
# All Front Door entries share the same filter:
#   AzureDiagnostics | where ResourceProvider == "MICROSOFT.CDN"
# ---------------------------------------------------------------------------
#
# Log categories:
#
#  FrontDoorAccessLog — one entry per HTTP/S request handled by a Front Door
#                       edge PoP.  Contains client IP, full URL, HTTP method
#                       and status, latency, cache status (HIT / MISS /
#                       CONFIG_NOCACHE), matched WAF policy, and TLS details.
#
#    Portal KQL — recent requests with key fields:
#      AzureDiagnostics
#      | where ResourceProvider == "MICROSOFT.CDN"
#      | where Category == "FrontdoorAccessLog"
#      | project TimeGenerated, clientIp_s, requestUri_s, httpStatusCode_s,
#                timeTaken_s, cacheStatus_s, pop_s, userAgent_s
#      | order by TimeGenerated desc
#
#    Portal KQL — 4xx/5xx error breakdown:
#      AzureDiagnostics
#      | where ResourceProvider == "MICROSOFT.CDN"
#      | where Category == "FrontdoorAccessLog"
#      | where toint(httpStatusCode_s) >= 400
#      | summarize count() by httpStatusCode_s, requestUri_s
#      | order by count_ desc
#
#  FrontDoorWebApplicationFirewallLog — WAF rule evaluations in both Detection
#                       and Prevention mode.  Covers custom rules (rate-limit,
#                       geo-block) and managed rule sets (DefaultRuleSet,
#                       BotManager) defined in the firewall policy below.
#                       action_s = "Block" means the request was dropped;
#                       "Log" means Detection mode matched but allowed through.
#
#    Portal KQL — all WAF actions with rule name and client IP:
#      AzureDiagnostics
#      | where ResourceProvider == "MICROSOFT.CDN"
#      | where Category == "FrontdoorWebApplicationFirewallLog"
#      | project TimeGenerated, action_s, ruleName_s, clientIp_s,
#                requestUri_s, policyMode_s, details_msg_s
#      | order by TimeGenerated desc
#
#    Portal KQL — blocked request count by rule (last 24 h):
#      AzureDiagnostics
#      | where ResourceProvider == "MICROSOFT.CDN"
#      | where Category == "FrontdoorWebApplicationFirewallLog"
#      | where action_s == "Block"
#      | summarize count() by ruleName_s, bin(TimeGenerated, 1h)
#      | order by TimeGenerated desc
#
#  FrontDoorHealthProbeLog — periodic synthetic probe results per origin.
#                       Fires approximately every 30 seconds automatically.
#                       Use this to distinguish "Front Door is not routing"
#                       from "the origin container / app is unhealthy".
#                       httpStatusCode_s == "0" means TCP-level failure
#                       (origin unreachable); non-2xx means app-level error.
#
#    Portal KQL — probe failures grouped by origin:
#      AzureDiagnostics
#      | where ResourceProvider == "MICROSOFT.CDN"
#      | where Category == "FrontdoorHealthProbeLog"
#      | where httpStatusCode_s != "200"
#      | summarize failures=count() by originName_s, httpStatusCode_s,
#                  bin(TimeGenerated, 5m)
#      | order by TimeGenerated desc
#
#  AllMetrics — pre-aggregated time-series counters and gauges: total request
#               count, origin latency (P50/P95/P99), 4xx rates, 5xx rates,
#               byte counters (inbound/outbound), and WebSocket counts.
#               Required for metric alert rules (cheaper than scanning raw
#               log rows for volume-based thresholds).
#
#    Portal: navigate to the Front Door profile → "Metrics" blade and select
#    any metric (e.g. "Request Count", "Origin Latency") to chart without KQL.
#
#    Portal KQL — hourly request volume from metrics:
#      AzureMetrics
#      | where ResourceProvider == "MICROSOFT.CDN"
#      | where MetricName == "RequestCount"
#      | summarize total=sum(Total) by bin(TimeGenerated, 1h)
#      | order by TimeGenerated desc
resource "azurerm_monitor_diagnostic_setting" "frontdoor_diagnostics" {
  name                       = "${var.app_name}-frontdoor-diagnostics"
  target_resource_id         = azurerm_cdn_frontdoor_profile.frontend_frontdoor.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  # log_analytics_destination_type is intentionally omitted — Dedicated mode is
  # not supported by Microsoft.Cdn/profiles and Azure silently reverts it to null.
  # Logs land in AzureDiagnostics with ResourceProvider == "MICROSOFT.CDN".

  # Per-request HTTP/S access log: client IP, URL, method, HTTP status, latency,
  # cache status (HIT/MISS/CONFIG_NOCACHE), PoP location, TLS version, WAF policy.
  # KQL: AzureDiagnostics | where ResourceProvider == "MICROSOFT.CDN"
  #      | where Category == "FrontdoorAccessLog"
  #      | project TimeGenerated, clientIp_s, requestUri_s, httpStatusCode_s,
  #                timeTaken_s, cacheStatus_s, pop_s | order by TimeGenerated desc
  enabled_log {
    category = "FrontdoorAccessLog"
  }

  # WAF rule evaluations: action_s = "Block" (Prevention) or "Log" (Detection).
  # Covers custom rules (RateLimitByIP, BlockByNonCAGeoMatch) and managed rule sets.
  # KQL: AzureDiagnostics | where ResourceProvider == "MICROSOFT.CDN"
  #      | where Category == "FrontdoorWebApplicationFirewallLog"
  #      | project TimeGenerated, action_s, ruleName_s, clientIp_s,
  #                requestUri_s, policyMode_s | order by TimeGenerated desc
  enabled_log {
    category = "FrontdoorWebApplicationFirewallLog"
  }

  # Synthetic probe results per origin (~every 30 s). httpStatusCode_s == "0"
  # means TCP failure (origin unreachable); non-2xx means app-level error.
  # KQL: AzureDiagnostics | where ResourceProvider == "MICROSOFT.CDN"
  #      | where Category == "FrontdoorHealthProbeLog"
  #      | where httpStatusCode_s != "200"
  #      | summarize failures=count() by originName_s, httpStatusCode_s, bin(TimeGenerated, 5m)
  enabled_log {
    category = "FrontdoorHealthProbeLog"
  }

  # Pre-aggregated counters/gauges for dashboards and metric alert rules.
  # View in Portal: Front Door profile → Metrics blade (no KQL needed).
  # KQL: AzureMetrics | where ResourceProvider == "MICROSOFT.CDN"
  #      | where MetricName == "RequestCount"
  #      | summarize total=sum(Total) by bin(TimeGenerated, 1h)
  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "frontend_firewall_policy" {
  name                = "${replace(var.app_name, "/[^a-zA-Z0-9]/", "")}frontendfirewall"
  resource_group_name = var.resource_group_name
  sku_name            = var.frontdoor_sku_name
  mode                = "Prevention"

  log_scrubbing {
    enabled = true

    scrubbing_rule {
      enabled        = true
      match_variable = "RequestHeaderNames"
      operator       = "Equals"
      selector       = "Authorization"
    }
    scrubbing_rule {
      enabled        = true
      match_variable = "RequestHeaderNames"
      operator       = "Equals"
      selector       = "api-key"
    }
  }
  # the 'managed_rule' code block is only supported with the "Premium_AzureFrontDoor" sku
  dynamic "managed_rule" {
    for_each = var.frontdoor_sku_name == "Premium_AzureFrontDoor" ? [
      {
        type    = "DefaultRuleSet"
        version = "1.0"
        action  = "Log"
      },
      {
        type    = "Microsoft_BotManagerRuleSet"
        version = "1.1"
        action  = "Block"
      },
      {
        type    = "BotProtection"
        version = "preview-0.1"
        action  = "Block"
      }
    ] : []
    content {
      type    = managed_rule.value.type
      version = managed_rule.value.version
      action  = managed_rule.value.action
    }
  }
  # Simple baseline rate limiter
  # Covers both IPv4 (0.0.0.0/0) and IPv6 (::/0) — Azure WAF IPMatch treats
  # these as separate address families; omitting ::/0 silently skips all IPv6
  # clients, which is the default for most modern dual-stack connections.
  custom_rule {
    action                         = "Block"
    enabled                        = true
    name                           = "RateLimitByIP"
    priority                       = 100
    rate_limit_duration_in_minutes = var.rate_limit_duration_in_minutes
    rate_limit_threshold           = var.rate_limit_threshold
    type                           = "RateLimitRule"
    match_condition {
      match_values       = ["0.0.0.0/0", "::/0"]
      match_variable     = "RemoteAddr"
      negation_condition = false
      operator           = "IPMatch"
    }
  }
  # Block Non-Canadian requests
  custom_rule {
    action   = "Block"
    enabled  = true
    name     = "BlockByNonCAGeoMatch"
    priority = 110
    type     = "MatchRule"
    match_condition {
      match_values       = ["CA"]
      match_variable     = "SocketAddr"
      negation_condition = true
      operator           = "GeoMatch"
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


