variable "app_env" {
  description = "The deployment environment (e.g., dev, test, prod)."
  type        = string
  nullable    = false
}

variable "app_name" {
  description = "The base name of the application. Used for naming Azure resources."
  type        = string
  nullable    = false
}

variable "appinsights_connection_string" {
  description = "The Application Insights connection string for monitoring."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "appinsights_instrumentation_key" {
  description = "The Application Insights instrumentation key."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "appinsights_resource_id" {
  description = "Resource ID of the Application Insights component used by this app. Used to include Azure's hidden-link tag on the App Service to prevent tag drift."
  type        = string
  nullable    = true
  default     = null
}

variable "common_tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "container_registry_url" {
  description = "The URL of the container registry to pull images from."
  type        = string
  nullable    = false
  default     = "https://ghcr.io"
}

variable "frontend_frontdoor_id" {
  description = "The ID of the Front Door profile for the frontend."
  type        = string
  nullable    = true
}

variable "frontend_frontdoor_resource_guid" {
  description = "The resource GUID of the Front Door profile for the frontend."
  type        = string
  nullable    = true
}

variable "frontend_image" {
  description = "The Docker image for the frontend application."
  type        = string
  nullable    = false
}

variable "frontend_subnet_id" {
  description = "The subnet ID for the frontend App Service."
  type        = string
  nullable    = false
}

variable "frontdoor_frontend_firewall_policy_id" {
  description = "The resource ID of the Front Door firewall policy for the frontend."
  type        = string
  nullable    = true
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  nullable    = false
}

variable "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace for diagnostics."
  type        = string
  nullable    = false
}

variable "repo_name" {
  description = "The repository name, used for resource naming."
  type        = string
  nullable    = false
}

variable "backend_url" {
  description = "Backend base URL for the frontend (e.g., https://<backend-host>). Used to set VITE_BACKEND_URL in the App Service container."
  type        = string
  nullable    = true
  default     = null
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create resources."
  type        = string
  nullable    = false
}


variable "app_service_sku_name_frontend" {
  description = "The SKU name for the frontend App Service plan."
  type        = string
  nullable    = false
}

variable "app_service_plan_worker_count" {
  description = <<-EOT
  App Service Plan worker count (instance count).

  Why this exists:
  - The AVM App Service Plan (serverfarm) module can default to multiple workers.
  - For Basic tiers (e.g., B1), requesting multiple workers can trigger Azure capacity/conflict errors (e.g., 409) depending on region/quota/availability.

  Recommended default:
  - Keep this at 1 for Basic SKUs unless you explicitly need more instances.

  References:
  - AVM serverfarm module: https://registry.terraform.io/modules/Azure/avm-res-web-serverfarm/azurerm/1.0.0
  - AzureRM Service Plan worker_count: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan#worker_count
  EOT
  type        = number
  default     = 1

  validation {
    condition     = var.app_service_plan_worker_count >= 1
    error_message = "app_service_plan_worker_count must be >= 1."
  }
}

variable "enable_frontdoor" {
  description = "Whether Front Door is enabled. When false, frontend is exposed directly via its default hostname."
  type        = bool
  nullable    = false
}

variable "enable_telemetry" {
  description = "Whether AVM modules should send telemetry."
  type        = bool
  default     = true
}
