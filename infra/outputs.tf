output "frontend_public_url" {
  description = "The public URL of the frontend (Front Door if enabled else App Service)"
  value       = module.frontend.frontend_url
}

# Container Apps outputs (when enabled) - Backend Only
output "container_apps_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = var.enable_container_apps ? module.container_apps[0].container_apps_environment_id : null
}

output "backend_container_app_url" {
  description = "Internal URL of the backend Container App"
  value       = var.enable_container_apps ? module.container_apps[0].backend_container_app_url : null
}

output "backend_container_app_fqdn" {
  description = "Internal FQDN of the backend Container App"
  value       = var.enable_container_apps ? module.container_apps[0].backend_container_app_fqdn : null
}

output "container_apps_static_ip" {
  description = "Static IP of the Container Apps Environment"
  value       = var.enable_container_apps ? module.container_apps[0].container_apps_environment_static_ip : null
}
