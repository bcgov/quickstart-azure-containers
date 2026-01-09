locals {
  diagnostic_settings = length(trimspace(var.log_analytics_workspace_id)) > 0 ? {
    default = {
      workspace_resource_id = var.log_analytics_workspace_id
    }
  } : {}

  private_endpoints = var.enable_private_endpoint ? {
    registry = {
      subnet_resource_id = var.private_endpoint_subnet_id

      # Azure Landing Zone policy typically manages DNS zone group association.
      # Keep DNS zone associations unmanaged here.
      private_dns_zone_resource_ids = []
    }
  } : {}
}
