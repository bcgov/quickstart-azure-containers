output "cloudbeaver_app_service_url" {
  description = "The URL of the CloudBeaver App Service"
  value       = var.enable_psql_sidecar ? "https://${module.backend.cloudbeaver_app_service_url}" : null
}

output "cdn_frontdoor_endpoint_url" {
  description = "The URL of the CDN Front Door endpoint"
  value       = module.frontend.frontend_url
}