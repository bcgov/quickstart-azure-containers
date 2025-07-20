output "cloudbeaver_app_service_url" {
  description = "The URL of the CloudBeaver App Service"
  value       = var.enable_psql_sidecar ? "https://${azurerm_linux_web_app.psql_sidecar[0].default_hostname}" : null
}

output "cdn_frontdoor_endpoint_url" {
  description = "The URL of the CDN Front Door endpoint"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.frontend_fd_endpoint.host_name}"
}