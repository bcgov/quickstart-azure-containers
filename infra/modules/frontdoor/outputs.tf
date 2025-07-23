output "firewall_policy_id" {
  description = "The ID of the Front Door firewall policy."
  value       = azurerm_cdn_frontdoor_firewall_policy.frontend_firewall_policy.id

}

output "frontdoor_id" {
  description = "The name of the Front Door endpoint."
  value       = azurerm_cdn_frontdoor_profile.frontend_frontdoor.id
}

output "frontdoor_resource_guid" {
  description = "The resource GUID of the Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.frontend_frontdoor.resource_guid
}
