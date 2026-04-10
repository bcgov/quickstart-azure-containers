# Container Apps Module Variables - Backend Only

variable "app_env" {
  description = "Application environment (dev, test, prod)"
  type        = string
  nullable    = false
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  nullable    = false
}

variable "app_service_frontend_url" {
  description = "URL of the App Service frontend for CORS configuration"
  type        = string
  nullable    = false
}

variable "appinsights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  sensitive   = true
  nullable    = false
}

variable "appinsights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  type        = string
  sensitive   = true
  nullable    = false
}

variable "backend_image" {
  description = "Container image for the backend API"
  type        = string
  nullable    = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  nullable    = false
}

variable "container_apps_subnet_id" {
  description = "Subnet ID for Container Apps Environment"
  type        = string
  nullable    = false
}

variable "container_cpu" {
  description = "CPU allocation for backend container app (in cores)"
  type        = number
  default     = 0.25
  nullable    = false
}

variable "container_memory" {
  description = "Memory allocation for backend container app"
  type        = string
  default     = "0.5Gi"
  nullable    = false
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  nullable    = false
}

variable "db_master_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
  nullable    = false
}

variable "enable_system_assigned_identity" {
  description = "Enable system assigned managed identity"
  type        = bool
  default     = true
  nullable    = false
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  nullable    = false
}

variable "log_level" {
  description = "Backend Winston/Nest log level for structured application logs that can flow to Application Insights."
  type        = string
  default     = "info"

  validation {
    condition     = contains(["error", "warn", "info", "http", "verbose", "debug", "silly"], var.log_level)
    error_message = "log_level must be one of: error, warn, info, http, verbose, debug, silly."
  }
}

variable "http_access_log_mode" {
  description = "Controls request access logging written to container stdout for LAW ingestion. Supported values: off, failures, all."
  type        = string
  default     = "failures"

  validation {
    condition     = contains(["off", "failures", "all"], var.http_access_log_mode)
    error_message = "http_access_log_mode must be one of: off, failures, all."
  }
}

variable "slow_query_log_threshold_ms" {
  description = "Emit Prisma slow-query diagnostics to container stdout when query duration meets or exceeds this threshold in milliseconds. Set to -1 to disable."
  type        = number
  default     = 1000

  validation {
    condition     = var.slow_query_log_threshold_ms >= -1
    error_message = "slow_query_log_threshold_ms must be greater than or equal to -1."
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Container Apps Environment"
  type        = string
  nullable    = false
}

variable "max_replicas" {
  description = "Maximum number of replicas for backend"
  type        = number
  default     = 10 # Higher max for Consumption workload
  nullable    = false
}

variable "min_replicas" {
  description = "Minimum number of replicas for backend"
  type        = number
  default     = 0 # Allow scale to zero for Consumption workload
  nullable    = false
}
variable "migrations_image" {
  description = "Container image for database migrations (Flyway)"
  type        = string
  nullable    = false
}

variable "postgres_host" {
  description = "PostgreSQL host endpoint"
  type        = string
  nullable    = false
}

variable "backend_postgres_host" {
  description = "PostgreSQL host endpoint used by the backend container at runtime."
  type        = string
  nullable    = false
}

variable "postgresql_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  nullable    = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  nullable    = false
}
variable "log_analytics_workspace_customer_id" {
  description = "Log Analytics Workspace customer ID (GUID) for Container Apps Environment logs"
  type        = string
  nullable    = false
}

variable "log_analytics_workspace_key" {
  description = "Log Analytics Workspace primary shared key for Container Apps Environment logs"
  type        = string
  sensitive   = true
  nullable    = false
}
