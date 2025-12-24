# -------------
# Azure API Management Module
# -------------
# This module creates an Azure API Management instance with v2 configuration
# following production-ready best practices for security, monitoring, and scaling

terraform {
  required_version = ">= 1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.53.0"
    }
  }
}

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
  sign_in {
    enabled = var.enable_sign_in
  }

  sign_up {
    enabled = var.enable_sign_up
    terms_of_service {
      consent_required = var.terms_of_service.consent_required
      enabled          = var.terms_of_service.enabled
      text             = var.terms_of_service.text
    }
  }

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

# Diagnostic Settings for monitoring and compliance
resource "azurerm_monitor_diagnostic_setting" "apim" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${azurerm_api_management.main.name}-diagnostics"
  target_resource_id         = azurerm_api_management.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Enable all available log categories
  dynamic "enabled_log" {
    for_each = var.diagnostic_log_categories
    content {
      category = enabled_log.value
    }
  }

  # Enable all available metric categories
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
