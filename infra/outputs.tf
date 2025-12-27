output "frontend_public_url" {
  description = "The public URL of the frontend (Front Door if enabled else App Service)"
  value       = var.enable_app_service_frontend ? module.frontend[0].frontend_url : ""
}

# -------------
# API Management Outputs
# -------------

output "apim_gateway_url" {
  description = "The URL of the API Management Gateway"
  value       = var.enable_apim ? module.apim[0].apim_gateway_url : null
}

output "apim_developer_portal_url" {
  description = "The URL of the API Management Developer Portal"
  value       = var.enable_apim ? module.apim[0].apim_developer_portal_url : null
}

output "apim_management_api_url" {
  description = "The URL of the API Management Management API"
  value       = var.enable_apim ? module.apim[0].apim_management_api_url : null
}

output "apim_name" {
  description = "The name of the API Management service"
  value       = var.enable_apim ? module.apim[0].apim_name : null
}
