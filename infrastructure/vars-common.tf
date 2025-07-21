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


variable "vnet_address_space" {
  type        = string
  description = "Address space for the virtual network, it is created by platform team"
}

variable "repo_name" {
  description = "Name of the repository, used for resource naming"
  type        = string
  default     = "quickstart-azure-containers"
}

