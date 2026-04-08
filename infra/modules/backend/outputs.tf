output "backend_url" {
  description = "The URL of the backend App Service"
  value       = module.backend_site.resource_uri
}

output "backend_app_service_name" {
  description = "The name of the backend App Service"
  value       = module.backend_site.name
}
