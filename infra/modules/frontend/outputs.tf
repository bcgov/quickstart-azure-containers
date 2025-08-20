output "frontend_url" {
  description = "The URL of the frontend application (Front Door if enabled else App Service)"
  value       = var.enable_frontdoor && can(azurerm_cdn_frontdoor_endpoint.frontend_fd_endpoint[0].host_name) ? "https://${azurerm_cdn_frontdoor_endpoint.frontend_fd_endpoint[0].host_name}" : "https://${azurerm_linux_web_app.frontend.default_hostname}"

}

output "possible_outbound_ip_addresses" {
  description = "Possible outbound IP addresses for the frontend application."
  value       = azurerm_linux_web_app.frontend.possible_outbound_ip_addresses
}
