output "name" {
  description = "The name of the Azure Container Registry."
  value       = module.acr.name
}

output "resource_id" {
  description = "The resource id of the Azure Container Registry."
  value       = module.acr.resource_id
}

output "login_server" {
  description = "The login server URL (e.g., <name>.azurecr.io)."
  value       = module.acr.resource.login_server
}

output "resource" {
  description = "Full azurerm_container_registry resource output from the AVM module."
  value       = module.acr.resource
}
