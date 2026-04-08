output "azure_proxy_url" {
  description = "The URL of the Azure Proxy App Service"
  value       = "https://${module.azure_proxy_site.resource_uri}"
  sensitive   = true
}

output "proxy_auth" {
  description = "The authentication string for the Azure Proxy"
  value       = "tunnel:${random_password.proxy_chisel_password.result}"
  sensitive   = true
}
