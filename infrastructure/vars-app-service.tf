
variable "apps_service_subnet_name" {
  description = "Name of the subnet for Container Apps"
  type        = string
  default     = "app-service-subnet"
}

variable "api_image" {
  description = "The image for the API container"
  type        = string
}

variable "flyway_image" {
  description = "The image for the Flyway container"
  type        = string
}

variable "frontend_image" {
  description = "The image for the Frontend container"
  type        = string
}

variable "node_env" {
  description = "Node.js environment"
  type        = string
  default     = "production"
}


variable "enable_psql_sidecar" {
  description = "Whether to enable the CloudBeaver database management container"
  type        = bool
  default     = true
}

variable "enable_app_service_logs" {
  description = "Enable detailed logging for App Service"
  type        = bool
  default     = true
}


variable "create_container_registry" {
  description = "Flag to create an Azure Container Registry"
  type        = bool
  default     = false
}

variable "log_analytics_retention_days" {
  description = "Number of days to retain data in Log Analytics Workspace"
  type        = number
  default     = 30
}

variable "log_analytics_sku" {
  description = "SKU for Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"
}


variable "app_service_sku_name_backend" {
  description = "SKU name for the backend App Service Plan"
  type        = string
  default     = "B1" # Basic tier 
}

variable "app_service_sku_name_frontend" {
  description = "SKU name for the frontend App Service Plan"
  type        = string
  default     = "B1" # Basic tier 
}
variable "backend_autoscale_enabled" {
  description = "Enable autoscaling for the backend App Service Plan"
  type        = bool
  default     = false
}