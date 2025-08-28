# -------------
# API Management Module Outputs
# -------------

output "apim_id" {
  description = "The ID of the API Management service."
  value       = azurerm_api_management.main.id
}

output "apim_name" {
  description = "The name of the API Management service."
  value       = azurerm_api_management.main.name
}

output "apim_gateway_url" {
  description = "The URL of the API Management Gateway."
  value       = azurerm_api_management.main.gateway_url
}

output "apim_gateway_regional_url" {
  description = "The regional URL of the API Management Gateway."
  value       = azurerm_api_management.main.gateway_regional_url
}

output "apim_management_api_url" {
  description = "The URL of the API Management Management API."
  value       = azurerm_api_management.main.management_api_url
}

output "apim_portal_url" {
  description = "The URL of the API Management Portal."
  value       = azurerm_api_management.main.portal_url
}

output "apim_developer_portal_url" {
  description = "The URL of the API Management Developer Portal."
  value       = azurerm_api_management.main.developer_portal_url
}

output "apim_scm_url" {
  description = "The URL of the API Management SCM endpoint."
  value       = azurerm_api_management.main.scm_url
}

output "apim_public_ip_addresses" {
  description = "The public IP addresses of the API Management service."
  value       = azurerm_api_management.main.public_ip_addresses
}

output "apim_private_ip_addresses" {
  description = "The private IP addresses of the API Management service."
  value       = azurerm_api_management.main.private_ip_addresses
}

output "apim_tenant_access" {
  description = "The tenant access information of the API Management service."
  value = {
    enabled       = azurerm_api_management.main.tenant_access[0].enabled
    primary_key   = azurerm_api_management.main.tenant_access[0].primary_key
    secondary_key = azurerm_api_management.main.tenant_access[0].secondary_key
    tenant_id     = azurerm_api_management.main.tenant_access[0].tenant_id
  }
  sensitive = true
}

output "apim_identity" {
  description = "The managed identity information of the API Management service."
  value = {
    type         = azurerm_api_management.main.identity[0].type
    identity_ids = azurerm_api_management.main.identity[0].identity_ids
    principal_id = azurerm_api_management.main.identity[0].principal_id
    tenant_id    = azurerm_api_management.main.identity[0].tenant_id
  }
}

output "apim_hostname_configurations" {
  description = "The hostname configurations of the API Management service."
  value       = azurerm_api_management.main.hostname_configuration
}

output "apim_additional_location" {
  description = "The additional locations of the API Management service."
  value       = azurerm_api_management.main.additional_location
}

# Application Insights Logger
output "apim_logger_id" {
  description = "The ID of the Application Insights logger (if enabled)."
  value       = var.enable_application_insights_logger && var.appinsights_instrumentation_key != null ? azurerm_api_management_logger.appinsights[0].id : null
}

# Named Values
output "apim_named_values" {
  description = "The named values created in the API Management service."
  value = {
    for k, v in azurerm_api_management_named_value.main : k => {
      id           = v.id
      name         = v.name
      display_name = v.display_name
      # Don't expose secret values
      value = v.secret ? "***HIDDEN***" : v.value
    }
  }
}

# Backend Services
output "apim_backends" {
  description = "The backend services configured in the API Management service."
  value = {
    for k, v in azurerm_api_management_backend.main : k => {
      id          = v.id
      name        = v.name
      protocol    = v.protocol
      url         = v.url
      title       = v.title
      description = v.description
    }
  }
}

# Diagnostic Settings
output "apim_diagnostic_setting_id" {
  description = "The ID of the diagnostic setting (if enabled)."
  value       = var.enable_diagnostic_settings ? azurerm_monitor_diagnostic_setting.apim[0].id : null
}

# Custom Domain
output "apim_custom_domain_id" {
  description = "The ID of the custom domain configuration (if configured)."
  value       = var.custom_domain_configuration != null ? azurerm_api_management_custom_domain.main[0].id : null
}
