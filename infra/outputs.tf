output "frontend_public_url" {
  description = "The public URL of the frontend (Front Door if enabled else App Service)"
  value       = module.frontend.frontend_url
}
