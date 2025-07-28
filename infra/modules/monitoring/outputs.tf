output "appinsights_connection_string" {
  description = "The Application Insights connection string."
  value       = azurerm_application_insights.main.connection_string
}

output "appinsights_instrumentation_key" {
  description = "The Application Insights instrumentation key."
  value       = azurerm_application_insights.main.instrumentation_key
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_key" {
  description = "The primary shared key for the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
}

output "log_analytics_workspace_workspaceId" {
  description = "The name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "application_insights_app_id" {
  description = "The Application Insights application ID."
  value       = azurerm_application_insights.main.app_id
}

output "application_insights_instrumentation_key" {
  description = "The Application Insights instrumentation key."
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The Application Insights connection string."
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}
