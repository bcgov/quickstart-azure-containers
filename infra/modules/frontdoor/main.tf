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
# Sends all Front Door telemetry to Log Analytics for security auditing and
# performance monitoring.  Three log categories are enabled:
#
#  FrontdoorAccessLog        — every HTTP/S request processed by the Front Door
#                              edge PoP.  Use this for traffic analysis, latency
#                              investigation, and compliance evidence.
#
#  FrontdoorWebApplicationFirewallLog — WAF rule matches (Detection / Prevention
#                              mode).  Essential for reviewing blocked/allowed
#                              requests from the custom + managed WAF rules
#                              configured in azurerm_cdn_frontdoor_firewall_policy.
#
#  FrontdoorHealthProbeLog   — results of the synthetic health probes sent to each
#                              origin.  Helps distinguish "Front Door not routing"
#                              from "origin is unhealthy".
#
#  AllMetrics                — origin latency, request count, byte counters, and
#                              4xx/5xx error rates surfaced in Azure Monitor.
resource "azurerm_monitor_diagnostic_setting" "frontdoor_diagnostics" {
  name                       = "${var.app_name}-frontdoor-diagnostics"
  target_resource_id         = azurerm_cdn_frontdoor_profile.frontend_frontdoor.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # HTTP access log – one entry per request routed through the Front Door edge.
  # Contains client IP, URL, HTTP status, latency, cache status, and matched rule.
  enabled_log {
    category = "FrontdoorAccessLog"
  }

  # WAF inspection log – emitted when a WAF rule (custom or managed) evaluates a
  # request.  Covers both Detection-mode observations and Prevention-mode blocks.
  enabled_log {
    category = "FrontdoorWebApplicationFirewallLog"
  }

  # Health probe log – records the periodic probe results for each origin.
  # Use to investigate origin failover events and latency spikes.
  enabled_log {
    category = "FrontdoorHealthProbeLog"
  }

  # Platform metrics (request volume, latency percentiles, error rates, etc.)
  # sent to Log Analytics for dashboarding and alert rules.
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
  custom_rule {
    action                         = "Block"
    enabled                        = true
    name                           = "RateLimitByIP"
    priority                       = 100
    rate_limit_duration_in_minutes = var.rate_limit_duration_in_minutes
    rate_limit_threshold           = var.rate_limit_threshold
    type                           = "RateLimitRule"
    match_condition {
      match_values       = ["0.0.0.0/0"]
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


