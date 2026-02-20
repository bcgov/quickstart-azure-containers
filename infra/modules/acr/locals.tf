# ---------------------------------------------------------------------------
# ACR Diagnostic Settings — passed to the AVM module via diagnostic_settings
# ---------------------------------------------------------------------------
# When var.log_analytics_workspace_id is set, the AVM azurerm_container_registry
# module forwards all log categories and metrics to Log Analytics.
# NOTE: ACR is not deployed by default in this project; these settings activate
# automatically when a registry is provisioned.
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
