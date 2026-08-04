# Replaces the Azure/avm-res-containerregistry-registry/azurerm module (last pinned at 0.6.0),
# whose newest release (0.7.0) still requires "azurerm >= 4.81.0, < 5.0.0" — incompatible with
# azurerm v5. Hand-rolled here so the repo can move to azurerm v5.
#
# `moved` blocks below preserve state continuity for anyone who already applied with the module.
moved {
  from = module.acr.azurerm_container_registry.this
  to   = azurerm_container_registry.acr
}

moved {
  from = module.acr.azurerm_private_endpoint.this_unmanaged_dns_zone_groups["registry"]
  to   = azurerm_private_endpoint.acr[0]
}

moved {
  from = module.acr.azurerm_monitor_diagnostic_setting.this["default"]
  to   = azurerm_monitor_diagnostic_setting.acr[0]
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.common_tags
}

resource "azurerm_private_endpoint" "acr" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.acr_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.acr_name}-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  tags = var.common_tags

  # Azure Landing Zone policy manages the private DNS zone group association, not Terraform.
  lifecycle {
    ignore_changes = [
      private_dns_zone_group,
      tags
    ]
  }
}

# ---------------------------------------------------------------------------
# ACR Diagnostic Settings
# ---------------------------------------------------------------------------
# Enabled automatically when var.log_analytics_workspace_id is set (ACR is deployed
# unconditionally by this template's root module).
#
# ── How to view logs in the Azure Portal ─────────────────────────────────────
# 1. Open the Log Analytics workspace in the Portal.
# 2. Click "Logs" in the left nav (under General).
# 3. Dismiss the query picker and paste any KQL below into the editor.
# 4. Adjust the time range picker (top-right) — ingestion lag is ~2-5 min.
# ---------------------------------------------------------------------------
#
# Log categories written by Azure Container Registry:
#
#  ContainerRegistryLoginEvents — records each successful and failed
#                                 authentication to the registry (docker login,
#                                 managed-identity pull, etc.).  Use for
#                                 access auditing and anomaly detection.
#
#    KQL — recent login events:
#      ContainerRegistryLoginEvents
#      | project TimeGenerated, CallerIpAddress, CorrelationId, Identity,
#                LoginServer, Region, ResultType, ResultDescription
#      | order by TimeGenerated desc
#
#    KQL — failed authentication attempts:
#      ContainerRegistryLoginEvents
#      | where ResultType != "Succeeded"
#      | summarize count() by CallerIpAddress, ResultDescription
#      | order by count_ desc
#
#  ContainerRegistryRepositoryEvents — records push, pull, delete, tag, and
#                                      untag operations on images and charts.
#                                      Use to audit who pulled or pushed which
#                                      image tag and when.
#
#    KQL — recent push and pull events:
#      ContainerRegistryRepositoryEvents
#      | where OperationName in ("Push", "Pull")
#      | project TimeGenerated, OperationName, Repository, Tag, CallerIpAddress,
#                Identity, LoginServer
#      | order by TimeGenerated desc
#
#    KQL — image delete activity:
#      ContainerRegistryRepositoryEvents
#      | where OperationName == "Delete"
#      | project TimeGenerated, Repository, Tag, CallerIpAddress, Identity
#      | order by TimeGenerated desc
#
#  AllMetrics — storage usage and throughput counters for the registry.
#
#    KQL — storage and throughput trends:
#      AzureMetrics
#      | where ResourceProvider == "MICROSOFT.CONTAINERREGISTRY"
#      | where MetricName in ("StorageUsed", "SuccessfulPullCount", "SuccessfulPushCount")
#      | summarize avg(Average) by MetricName, bin(TimeGenerated, 1h)
#      | order by TimeGenerated desc
# ---------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "acr" {
  count                      = length(trimspace(var.log_analytics_workspace_id)) > 0 ? 1 : 0
  name                       = "${var.acr_name}-diagnostics"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
