# Container Apps Module Variables - Backend Only

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "app_env" {
  description = "Application environment (dev, test, prod)"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

# Container Apps Environment Configuration
variable "container_apps_subnet_id" {
  description = "Subnet ID for Container Apps Environment"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Container Apps Environment"
  type        = string
}

variable "log_analytics_workspace_key" {
  description = "Log Analytics Workspace key for Container Apps Environment"
  type        = string
  sensitive   = true
}

# Backend Container Image
variable "backend_image" {
  description = "Container image for the backend API"
  type        = string
}

# Backend Configuration
variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "postgres_host" {
  description = "PostgreSQL host endpoint"
  type        = string
}

variable "postgresql_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
}

variable "db_master_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}

# Monitoring Configuration
variable "appinsights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  sensitive   = true
}

variable "appinsights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  type        = string
  sensitive   = true
}

# App Service Frontend Integration
variable "app_service_frontend_url" {
  description = "URL of the App Service frontend for CORS configuration"
  type        = string
}

# Container Apps Configuration
variable "container_cpu" {
  description = "CPU allocation for backend container app (in cores)"
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory allocation for backend container app"
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum number of replicas for backend"
  type        = number
  default     = 0 # Allow scale to zero for Consumption workload
}

variable "max_replicas" {
  description = "Maximum number of replicas for backend"
  type        = number
  default     = 10 # Higher max for Consumption workload
}

# Security
variable "enable_system_assigned_identity" {
  description = "Enable system assigned managed identity"
  type        = bool
  default     = true
}
