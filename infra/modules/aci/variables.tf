variable "app_name" {
  description = "The base name of the application. Used for naming Azure resources."
  type        = string
  nullable    = false
}

variable "common_tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "container_instance_subnet_id" {
  description = "The subnet ID for the Flyway Azure Container Instance."
  type        = string
  nullable    = false
}

variable "dns_servers" {
  description = "A list of DNS server IP addresses for the container group."
  type        = list(string)
  nullable    = false
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

variable "log_analytics_workspace_key" {
  description = "The primary shared key for the Log Analytics workspace."
  type        = string
  nullable    = false
}


variable "resource_group_name" {
  description = "The name of the resource group in which to create resources."
  type        = string
  nullable    = false
}

variable "enable_telemetry" {
  description = "Controls whether AVM telemetry is enabled."
  type        = bool
  default     = true
}
