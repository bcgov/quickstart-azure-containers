# -------------
# API Management Module Variables
# -------------

variable "app_name" {
  description = "The base name of the application. Used for naming Azure resources."
  type        = string
  nullable    = false
}

variable "app_env" {
  description = "The deployment environment (e.g., dev, test, prod)."
  type        = string
  nullable    = false
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the API Management service."
  type        = string
  nullable    = false
}

variable "common_tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

# APIM Specific Variables
variable "publisher_name" {
  description = "The name of the publisher/company."
  type        = string
  nullable    = false
}

variable "publisher_email" {
  description = "The email address of the publisher/company."
  type        = string
  nullable    = false
}

variable "sku_name" {
  description = "The SKU of the API Management service. Possible values are StandardV2 and PremiumV2."
  type        = string
  nullable    = false
}


variable "subnet_id" {
  description = "The subnet ID for VNet integration. Leave null to disable VNet integration."
  type        = string
  nullable    = false
}

# Diagnostic Settings
variable "enable_diagnostic_settings" {
  description = "Whether to enable diagnostic settings for the API Management service."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for diagnostic settings."
  type        = string
  default     = null
}

variable "diagnostic_log_categories" {
  description = "List of log categories to enable for diagnostic settings."
  type        = list(string)
  default = [
    "GatewayLogs",
    "WebSocketConnectionLogs",
    "DeveloperPortalAuditLogs"
  ]
}

variable "diagnostic_metric_categories" {
  description = "List of metric categories to enable for diagnostic settings."
  type        = list(string)
  default = [
    "AllMetrics"
  ]
}

# Custom Domain Configuration
variable "custom_domain_configuration" {
  description = "Custom domain configuration for the API Management service."
  type = object({
    gateway = optional(object({
      host_name                    = string
      certificate                  = optional(string)
      certificate_password         = optional(string)
      negotiate_client_certificate = optional(bool, false)
    }))
    developer_portal = optional(object({
      host_name                    = string
      certificate                  = optional(string)
      certificate_password         = optional(string)
      negotiate_client_certificate = optional(bool, false)
    }))
  })
  default = null
}

# Application Insights Integration
variable "enable_application_insights_logger" {
  description = "Whether to enable Application Insights logger for the API Management service."
  type        = bool
  default     = false
}

variable "appinsights_instrumentation_key" {
  description = "The Application Insights instrumentation key."
  type        = string
  sensitive   = true
  nullable    = false
}


# Global Policy
variable "global_policy_xml" {
  description = "The XML content for the global API Management policy."
  type        = string
  default     = null
}

# Named Values (Key-Value pairs for configuration)
variable "named_values" {
  description = "A map of named values (key-value pairs) to create in the API Management service."
  type = map(object({
    display_name = string
    value        = string
    secret       = optional(bool, false)
    tags         = optional(list(string), [])
  }))
  default = {}
}

# Backend Services
variable "backend_services" {
  description = "A map of backend services to configure in the API Management service."
  type = map(object({
    protocol    = string
    url         = string
    description = optional(string)
    title       = optional(string)
    credentials = optional(object({
      certificate = optional(list(string))
      query       = optional(map(string))
      header      = optional(map(string))
      authorization = optional(object({
        scheme    = string
        parameter = string
      }))
    }))
    tls = optional(object({
      validate_certificate_chain = optional(bool, true)
      validate_certificate_name  = optional(bool, true)
    }))
  }))
  default = {}
}

# Additional security settings
variable "enable_sign_in" {
  description = "Whether sign-in is enabled for the developer portal."
  type        = bool
  default     = true
}

variable "enable_sign_up" {
  description = "Whether sign-up is enabled for the developer portal."
  type        = bool
  default     = true
}

variable "terms_of_service" {
  description = "Terms of service configuration for the developer portal."
  type = object({
    consent_required = optional(bool, false)
    enabled          = optional(bool, false)
    text             = optional(string)
  })
  default = {
    consent_required = false
    enabled          = false
    text             = null
  }
}
