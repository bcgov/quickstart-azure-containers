output "cloudbeaver_app_service_url" {
  description = "The URL of the CloudBeaver App Service"
  value       = var.enable_psql_sidecar ? "https://${azurerm_linux_web_app.psql_sidecar[0].default_hostname}" : null
}
output "backend_app_service_url" {
  description = "The URL of the Backend App Service"
  value       = "https://${azurerm_linux_web_app.backend.default_hostname}"
}

output "cdn_frontdoor_endpoint_url" {
  description = "The URL of the CDN Front Door endpoint"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.frontend_fd_endpoint.host_name}"
}

output "storage_account_name" {
  description = "The name of the Storage Account for static content"
  value       = azurerm_storage_account.static_content.name
}

output "static_content_url" {
  description = "The URL of the static content in the Storage Account"
  value       = "https://${azurerm_storage_account.static_content.primary_blob_host}/$web"
}

output "cdn_frontdoor_static_content_url" {
  description = "The URL of the static content in the CDN Front Door"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.static_fd_endpoint.host_name}"
}

output "cdn_frontdoor_static_content_profile_name" {
  description = "The static content front door profile name"
  value       = azurerm_cdn_frontdoor_profile.static_frontdoor.name
}

output "cdn_frontdoor_static_content_endpoint_name" {
  description = "The static content front door endpoint name"
  value       = azurerm_cdn_frontdoor_endpoint.static_fd_endpoint.name
}

output "resource_group_name" {
  description = "The resource group name"
  value       = azurerm_resource_group.main.name
}