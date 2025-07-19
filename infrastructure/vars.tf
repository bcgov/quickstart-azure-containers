/**
  * Terraform variables for Azure Container Apps and related resources
  * This file defines the variables used across the infrastructure setup.
  POSTGRES VARS
*/
variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "app_env" {
  description = "Application environment (dev, test, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Canada Central"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vnet_name" {
  description = "Name of the existing virtual network"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "Resource group name where the virtual network exists"
  type        = string
}


variable "postgresql_admin_username" {
  description = "Administrator username for PostgreSQL server"
  type        = string
  default     = "pgadmin"
}

variable "postgresql_sku_name" {
  description = "SKU name for PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms" # Basic SKU for development purposes
}

variable "postgresql_storage_mb" {
  description = "Storage in MB for PostgreSQL server"
  type        = number
  default     = 32768
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = false
}

variable "ha_enabled" {
  description = "Enable high availability"
  type        = bool
  default     = false
}

variable "standby_availability_zone" {
  description = "Availability zone for standby replica"
  type        = string
  default     = "2"
}

variable "auto_grow_enabled" {
  description = "Enable auto-grow for storage"
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "app"
}


variable "db_master_password" {
  description = "Master password for the PostgreSQL server"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_master_password) >= 12
    error_message = "The db_master_password must be at least 12 characters long."
  }
}
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

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

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Azure client ID for the service principal"
  type        = string
  sensitive   = true
}

variable "use_oidc" {
  description = "Use OIDC for authentication"
  type        = bool
  default     = true
}

variable "web_subnet_name" {
  description = "Name of the web subnet for APIM deployment"
  type        = string
  default     = "web-subnet"
}

variable "private_endpoint_subnet_name" {
  description = "Name of the subnet for private endpoints"
  type        = string
  default     = "privateendpoints-subnet"

}
variable "container_instance_subnet_name" {
  description = "Name of the subnet for container instances"
  type        = string
  default     = "container-instance-subnet"
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
variable "enable_private_endpoint" {
  description = "Enable private endpoint for PostgreSQL Flexible Server"
  type        = bool
  default     = false
}

variable "vnet_address_space" {
  type        = string
  description = "Address space for the virtual network, it is created by platform team"
}

variable "repo_name" {
  description = "Name of the repository, used for resource naming"
  type        = string
  default     = "quickstart-azure-containers"
}
# Add your variable declarations below

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

variable "is_postgis_enabled" {
  description = "Enable PostGIS extension for PostgreSQL Flexible Server"
  type        = bool
  default     = false
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