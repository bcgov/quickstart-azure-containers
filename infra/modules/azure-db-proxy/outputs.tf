output "azure_db_proxy_url" {
  description = "The URL of the Azure DB Proxy App Service"
  value       = azurerm_linux_web_app.azure_db_proxy.default_hostname
}

