variable "app_name" {
  description = "Name of the application"
  type        = string
  nullable    = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  nullable    = false
}

variable "frontdoor_sku_name" {
  description = "The SKU name for the Front Door."
  type        = string
  nullable    = false
}

variable "rate_limit_duration_in_minutes" {
  description = "Duration in minutes for rate limiting."
  type        = number
  nullable    = false
}

variable "rate_limit_threshold" {
  description = "Request threshold for rate limiting."
  type        = number
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  nullable    = false
}
