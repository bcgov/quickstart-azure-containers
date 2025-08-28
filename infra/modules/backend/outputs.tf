output "cloudbeaver_app_service_url" {
  description = "The URL of the CloudBeaver App Service"
  value       = var.enable_cloudbeaver ? "https://${azurerm_linux_web_app.psql_sidecar[0].default_hostname}" : null
}

output "backend_url" {
  description = "The URL of the backend App Service"
  value       = azurerm_linux_web_app.backend.default_hostname
}

output "backend_app_service_name" {
  description = "The name of the backend App Service"
  value       = azurerm_linux_web_app.backend.name
}
