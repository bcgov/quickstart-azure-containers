resource "azurerm_monitor_action_group" "application" {
  count               = local.alerts_enabled ? 1 : 0
  name                = "${var.app_name}-app-ag"
  resource_group_name = var.resource_group_name
  short_name          = "appalert"

  dynamic "email_receiver" {
    for_each = {
      for index, email in var.alert_emails : index => email
    }
    content {
      name                    = format("email-%02d", tonumber(email_receiver.key) + 1)
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  tags = var.common_tags
}

resource "azurerm_monitor_smart_detector_alert_rule" "application" {
  for_each            = local.alerts_enabled ? local.smart_detectors : {}
  name                = "${var.app_name}-${each.key}"
  resource_group_name = var.resource_group_name
  scope_resource_ids  = [var.application_insights_id]
  description         = each.value.description
  detector_type       = each.value.detector
  severity            = each.value.severity
  frequency           = each.value.frequency
  throttling_duration = "PT1H"

  action_group {
    ids = [azurerm_monitor_action_group.application[0].id]
  }

  tags = var.common_tags
}

moved {
  from = azurerm_monitor_scheduled_query_rules_alert_v2.runtime_issues[0]
  to   = azurerm_monitor_scheduled_query_rules_alert_v2.application["runtime_issues"]
}

moved {
  from = azurerm_monitor_scheduled_query_rules_alert_v2.database_connectivity[0]
  to   = azurerm_monitor_scheduled_query_rules_alert_v2.application["database_connectivity"]
}

moved {
  from = azurerm_monitor_scheduled_query_rules_alert_v2.backend_http_5xx[0]
  to   = azurerm_monitor_scheduled_query_rules_alert_v2.application["backend_http_5xx"]
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "application" {
  for_each            = local.alerts_enabled ? local.scheduled_query_alerts : {}
  name                = "${var.app_name}-${each.value.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = each.value.display_name
  description         = each.value.description

  evaluation_frequency = local.scheduled_query_default_evaluation_frequency
  window_duration      = local.scheduled_query_window_duration
  scopes               = each.value.scopes
  severity             = each.value.severity
  enabled              = true

  dynamic "criteria" {
    for_each = [each.value.criteria]
    content {
      query                   = criteria.value.query
      operator                = "GreaterThanOrEqual"
      threshold               = criteria.value.threshold
      time_aggregation_method = "Count"

      failing_periods {
        minimum_failing_periods_to_trigger_alert = 1
        number_of_evaluation_periods             = 1
      }
    }
  }

  dynamic "action" {
    for_each = [each.value.action]
    content {
      action_groups = [azurerm_monitor_action_group.application[0].id]
      custom_properties = {
        alert_scope = action.value.alert_scope
        signal_type = action.value.signal_type
      }
    }
  }

  auto_mitigation_enabled = true
  skip_query_validation   = each.value.skip_query_validation
  tags                    = var.common_tags
}

resource "azurerm_monitor_metric_alert" "app_service_http_5xx" {
  count                    = local.alerts_enabled && var.enable_app_service_backend ? 1 : 0
  name                     = "${var.app_name}-appservice-http5xx"
  resource_group_name      = var.resource_group_name
  scopes                   = [var.app_service_backend_id]
  description              = "Detect elevated server error volume on the backend App Service."
  severity                 = 2
  frequency                = "PT1M"
  window_size              = "PT5M"
  auto_mitigate            = true
  target_resource_type     = "Microsoft.Web/sites"
  target_resource_location = var.location

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThanOrEqual"
    threshold        = var.app_service_http_5xx_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.application[0].id
  }

  tags = var.common_tags
}

resource "azurerm_monitor_metric_alert" "container_app_restarts" {
  count                    = local.alerts_enabled && var.enable_container_apps_backend ? 1 : 0
  name                     = "${var.app_name}-containerapp-restarts"
  resource_group_name      = var.resource_group_name
  scopes                   = [var.container_app_id]
  description              = "Detect repeated backend container restarts in Azure Container Apps."
  severity                 = 2
  frequency                = "PT5M"
  window_size              = "PT15M"
  auto_mitigate            = true
  target_resource_type     = "Microsoft.App/containerapps"
  target_resource_location = var.location

  criteria {
    metric_namespace = "Microsoft.App/containerapps"
    metric_name      = "RestartCount"
    aggregation      = "Total"
    operator         = "GreaterThanOrEqual"
    threshold        = var.container_app_restart_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.application[0].id
  }

  tags = var.common_tags
}
