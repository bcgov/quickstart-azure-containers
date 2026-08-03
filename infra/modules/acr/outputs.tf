output "name" {
  description = "The name of the Azure Container Registry."
  value       = azurerm_container_registry.acr.name
}

output "resource_id" {
  description = "The resource id of the Azure Container Registry."
  value       = azurerm_container_registry.acr.id
}

output "login_server" {
  description = "The login server URL (e.g., <name>.azurecr.io)."
  value       = azurerm_container_registry.acr.login_server
}

output "resource" {
  description = "Full azurerm_container_registry resource output."
  value       = azurerm_container_registry.acr
}
