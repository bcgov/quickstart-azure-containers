# Backend App Service Plan
resource "azurerm_service_plan" "backend" {
  name                = "${var.app_name}-backend-asp"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku_name_backend
  tags                = var.common_tags
  lifecycle {
    ignore_changes = [tags]
  }
}

# Backend App Service
locals {
  postgres_password_kv_secret_uri = try(trimspace(var.postgres_password_key_vault_secret_uri), "")
  use_kv_postgres_password        = var.enable_postgres_password_kv_reference
  postgres_password_setting       = local.use_kv_postgres_password ? "@Microsoft.KeyVault(SecretUri=${local.postgres_password_kv_secret_uri})" : var.db_master_password
}

resource "azurerm_linux_web_app" "backend" {
  name                      = "${var.repo_name}-${var.app_env}-api"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  service_plan_id           = azurerm_service_plan.backend.id
  https_only                = true
  virtual_network_subnet_id = var.backend_subnet_id
  identity {
    type = "SystemAssigned"
  }
  site_config {
    always_on                               = true
    container_registry_use_managed_identity = true
    minimum_tls_version                     = "1.3"
    health_check_path                       = "/api/health"
    health_check_eviction_time_in_min       = 2
    application_stack {
      docker_image_name   = var.api_image
      docker_registry_url = var.container_registry_url
    }
    ftps_state = "Disabled"
    cors {
      allowed_origins     = ["*"]
      support_credentials = false
    }
    dynamic "ip_restriction" {
      for_each = split(",", var.frontend_possible_outbound_ip_addresses)
      content {
        ip_address                = ip_restriction.value != "" ? "${ip_restriction.value}/32" : null
        virtual_network_subnet_id = ip_restriction.value == "" ? var.app_service_subnet_id : null
        service_tag               = ip_restriction.value == "" ? "AppService" : null
        action                    = "Allow"
        name                      = "AFInbound${replace(ip_restriction.value, ".", "")}"
        priority                  = 100
      }
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
    # When Front Door disabled, allow all traffic unless further restrictions desired.
    dynamic "ip_restriction" {
      for_each = var.enable_frontdoor ? [1] : []
      content {
        name        = "DenyAll"
        action      = "Deny"
        priority    = 500
        ip_address  = "0.0.0.0/0"
        description = "Deny all other traffic"
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
    POSTGRES_PASSWORD                     = local.postgres_password_setting
    POSTGRES_DATABASE                     = var.database_name
    WEBSITE_SKIP_RUNNING_KUDUAGENT        = "false"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE   = "false"
    WEBSITE_ENABLE_SYNC_UPDATE_SITE       = "1"
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

resource "azurerm_role_assignment" "backend_webapp_kv_secrets_user" {
  count = local.use_kv_postgres_password ? 1 : 0

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.backend.identity[0].principal_id
}

# Backend Autoscaler
resource "azurerm_monitor_autoscale_setting" "backend_autoscale" {
  name                = "${var.app_name}-backend-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_service_plan.backend.id
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
        metric_resource_id = azurerm_service_plan.backend.id
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
        metric_resource_id = azurerm_service_plan.backend.id
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

# Backend Diagnostics
resource "azurerm_monitor_diagnostic_setting" "backend_diagnostics" {
  name                       = "${var.app_name}-backend-diagnostics"
  target_resource_id         = azurerm_linux_web_app.backend.id
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
