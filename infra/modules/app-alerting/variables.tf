variable "app_name" {
  description = "Base application name used for alert resource naming."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Resource group where alert resources are created."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Azure region for alert resources."
  type        = string
  nullable    = false
}

variable "common_tags" {
  description = "Tags to apply to alert resources."
  type        = map(string)
  nullable    = false
}

variable "enable_alerts" {
  description = "Whether application alert resources should be created when recipients are configured."
  type        = bool
  nullable    = false
}

variable "alert_emails" {
  description = "Email recipients for application alert notifications."
  type        = list(string)
  nullable    = false
}

variable "application_insights_id" {
  description = "Resource ID of the Application Insights component that stores backend telemetry."
  type        = string
  nullable    = false
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace used for host and diagnostic log alerts."
  type        = string
  nullable    = false
}

variable "app_service_backend_id" {
  description = "Resource ID of the backend App Service, if deployed."
  type        = string
  default     = null
  nullable    = true
}

variable "container_app_id" {
  description = "Resource ID of the backend Container App, if deployed."
  type        = string
  default     = null
  nullable    = true
}

variable "runtime_issue_log_threshold" {
  description = "Number of matching runtime failure log entries within the alert window required to trigger the host runtime issue alert."
  type        = number
  default     = 2

  validation {
    condition     = var.runtime_issue_log_threshold >= 1
    error_message = "runtime_issue_log_threshold must be greater than or equal to 1."
  }
}

variable "database_connectivity_issue_threshold" {
  description = "Number of matching database connectivity errors within the alert window required to trigger the connectivity alert."
  type        = number
  default     = 2

  validation {
    condition     = var.database_connectivity_issue_threshold >= 1
    error_message = "database_connectivity_issue_threshold must be greater than or equal to 1."
  }
}

variable "app_service_http_5xx_threshold" {
  description = "Total App Service HTTP 5xx responses in five minutes required to trigger the platform error alert."
  type        = number
  default     = 5

  validation {
    condition     = var.app_service_http_5xx_threshold >= 1
    error_message = "app_service_http_5xx_threshold must be greater than or equal to 1."
  }
}

variable "container_app_restart_threshold" {
  description = "Total backend container restarts in fifteen minutes required to trigger the restart alert."
  type        = number
  default     = 3

  validation {
    condition     = var.container_app_restart_threshold >= 1
    error_message = "container_app_restart_threshold must be greater than or equal to 1."
  }
}
