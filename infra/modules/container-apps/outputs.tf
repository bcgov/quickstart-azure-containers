# Container Apps Environment outputs
output "container_apps_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.id
}

output "container_apps_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.name
}

output "container_apps_environment_fqdn" {
  description = "Default domain of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.default_domain
}

output "container_apps_environment_static_ip" {
  description = "Static IP of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.static_ip_address
}

# Backend Container App outputs
output "backend_container_app_id" {
  description = "ID of the backend Container App"
  value       = azurerm_container_app.backend.id
}

output "backend_container_app_name" {
  description = "Name of the backend Container App"
  value       = azurerm_container_app.backend.name
}

output "backend_container_app_fqdn" {
  description = "Internal FQDN of the backend Container App"
  value       = azurerm_container_app.backend.ingress[0].fqdn
}

output "backend_container_app_url" {
  description = "Internal URL of the backend Container App"
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

# Container Apps outbound IP addresses
output "backend_outbound_ip_addresses" {
  description = "Outbound IP addresses for the backend Container App"
  value       = azurerm_container_app.backend.outbound_ip_addresses
}

# Managed Identity outputs
output "backend_container_app_identity_principal_id" {
  description = "Principal ID of the backend Container App managed identity"
  value       = azurerm_container_app.backend.identity[0].principal_id
}

output "backend_container_app_identity_tenant_id" {
  description = "Tenant ID of the backend Container App managed identity"
  value       = azurerm_container_app.backend.identity[0].tenant_id
}
