output "frontend_public_url" {
  description = "The public URL of the frontend (Front Door if enabled else App Service)"
  value       = var.enable_app_service_frontend ? module.frontend[0].frontend_url : ""
}

# -------------
# ACR Outputs
# -------------

output "acr_name" {
  description = "The name of the Azure Container Registry."
  value       = try(module.acr[0].name, null)
}

output "acr_resource_id" {
  description = "The resource ID of the Azure Container Registry."
  value       = try(module.acr[0].resource_id, null)
}

output "acr_login_server" {
  description = "The ACR login server (e.g., <name>.azurecr.io)."
  value       = try(module.acr[0].login_server, null)
}

# -------------
# API Management Outputs
# -------------

output "apim_gateway_url" {
  description = "The URL of the API Management Gateway"
  value       = try(module.apim[0].apim_gateway_url, null)
}

output "apim_developer_portal_url" {
  description = "The URL of the API Management Developer Portal"
  value       = try(module.apim[0].apim_developer_portal_url, null)
}

output "apim_management_api_url" {
  description = "The URL of the API Management Management API"
  value       = try(module.apim[0].apim_management_api_url, null)
}

output "apim_name" {
  description = "The name of the API Management service"
  value       = try(module.apim[0].apim_name, null)
}
# -------------
# Azure Proxy Outputs
# -------------
output "azure_proxy_url" {
  description = "The URL of the Azure Proxy App Service"
  value       = var.enable_azure_proxy ? module.azure_proxy[0].azure_proxy_url : null
  sensitive   = true
}
output "azure_proxy_auth" {
  description = "The authentication string for the Azure Proxy"
  value       = var.enable_azure_proxy ? module.azure_proxy[0].proxy_auth : null
  sensitive   = true
}
