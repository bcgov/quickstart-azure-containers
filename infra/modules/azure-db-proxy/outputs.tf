output "azure_db_proxy_url" {
  description = "The URL of the Azure DB Proxy App Service"
  value       = azurerm_linux_web_app.azure_db_proxy.default_hostname
}

output "proxy_auth" {
  description = "The authentication string for the Azure DB Proxy"
  value       = "tunnel:${random_password.proxy_chisel_password.result}"
  sensitive   = true
}
