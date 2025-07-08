output "container_app_fqdn" {
  description = "FQDN of the Container App"
  value       = azurerm_container_app.api.latest_revision_fqdn
}

output "container_app_name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.api.name
}

output "container_app_environment_id" {
  description = "ID of the Container App Environment"
  value       = azurerm_container_app_environment.main.id
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "container_registry_login_server" {
  description = "Login server of the Container Registry"
  value       = var.create_container_registry ? azurerm_container_registry.main[0].login_server : null
}

output "user_assigned_identity_id" {
  description = "ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.container_apps.id
}

output "user_assigned_identity_principal_id" {
  description = "Principal ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.container_apps.principal_id
}

output "resource_group_name" {
  description = "Name of the API resource group"
  value       = azurerm_resource_group.api.name
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.name
}


output "application_gateway_fqdn" {
  description = "FQDN of the Application Gateway public IP"
  value       = azurerm_public_ip.app_gateway.fqdn
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.ip_address
}

output "application_gateway_url" {
  description = "URL of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.fqdn != null ? "https://${azurerm_public_ip.app_gateway.fqdn}" : "https://${azurerm_public_ip.app_gateway.ip_address}"
}