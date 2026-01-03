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
  default     = 0.5
  nullable    = false
}

variable "container_memory" {
  description = "Memory allocation for backend container app"
  type        = string
  default     = "1Gi"
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

variable "key_vault_id" {
  description = "Resource ID of the Key Vault used for secret references"
  type        = string
  nullable    = false
}

variable "postgres_password_key_vault_secret_id" {
  description = "Optional Key Vault secret ID (id or versionless_id) for POSTGRES_PASSWORD. When set, Container Apps will reference Key Vault instead of storing the secret value."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.postgres_password_key_vault_secret_id == null || var.enable_system_assigned_identity
    error_message = "postgres_password_key_vault_secret_id requires enable_system_assigned_identity = true so the Container App can access Key Vault."
  }
}

variable "enable_postgres_password_kv_reference" {
  description = "Enable Key Vault secret reference for postgres-password and grant the Container App managed identity access to Key Vault secrets."
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = !var.enable_postgres_password_kv_reference || var.enable_system_assigned_identity
    error_message = "enable_postgres_password_kv_reference requires enable_system_assigned_identity = true so the Container App can access Key Vault."
  }
}
