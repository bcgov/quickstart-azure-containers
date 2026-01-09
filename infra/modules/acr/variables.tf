variable "acr_name" {
  description = "The name of the Azure Container Registry (5-50 lowercase alphanumeric)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.acr_name))
    error_message = "acr_name must be 5-50 characters, lowercase alphanumeric only (a-z, 0-9)."
  }
}

variable "location" {
  description = "Azure region where the resource should be deployed."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "The resource group where the resources will be deployed."
  type        = string
  nullable    = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "sku" {
  description = <<-EOT
  The SKU name of the Container Registry. Possible values: Basic, Standard, Premium.

  Pricing/feature guidance (see official pricing page for current numbers):
  - Basic: lowest cost, best for dev/test and light usage.
  - Standard: higher throughput/limits than Basic for most production workloads.
  - Premium: adds advanced enterprise features; required for Private Link/private endpoints.

  Official pricing: https://azure.microsoft.com/en-us/pricing/details/container-registry/#pricing
  EOT
  type        = string
  default     = "Premium"
}

variable "admin_enabled" {
  description = "Specifies whether the admin user is enabled."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = <<-EOT
  Specifies whether public access is permitted.

  Note (BC Gov Azure Landing Zone): public ACR is allowed, and Basic SKU is allowed.
  If you intend to use Private Link/private endpoints, keep this disabled and use Premium SKU.
  EOT
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = <<-EOT
  Whether to create a private endpoint (Private Link) for the registry.

  Premium SKU is required when private endpoints/private connectivity are expected.
  EOT
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet resource ID used to deploy the private endpoint. Required when enable_private_endpoint=true."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_private_endpoint || length(trimspace(var.private_endpoint_subnet_id)) > 0
    error_message = "private_endpoint_subnet_id must be set when enable_private_endpoint is true."
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID for diagnostic settings. Leave empty to disable diagnostics."
  type        = string
  default     = ""
}

variable "enable_telemetry" {
  description = "Controls whether AVM telemetry is enabled."
  type        = bool
  default     = true
}
