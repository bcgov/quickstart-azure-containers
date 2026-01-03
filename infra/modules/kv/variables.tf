variable "app_name" {
  description = "Application name (used for resource naming)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
}

variable "tenant_id" {
  description = "Entra ID tenant ID"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
}

variable "postgres_password_secret_name" {
  description = "Key Vault secret name for the PostgreSQL password"
  type        = string
  default     = "postgres-admin-password"
}

variable "postgres_password_length" {
  description = "Length of generated PostgreSQL password"
  type        = number
  default     = 32
}

variable "key_vault_sku_name" {
  description = "Key Vault SKU name"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], lower(var.key_vault_sku_name))
    error_message = "key_vault_sku_name must be 'standard' or 'premium'."
  }
}

variable "key_vault_enable_rbac_authorization" {
  description = "Enable RBAC authorization on Key Vault (recommended for Landing Zones)"
  type        = bool
  default     = true
}

variable "key_vault_soft_delete_retention_days" {
  description = "Soft delete retention days"
  type        = number
  default     = 90
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection on Key Vault"
  type        = bool
  default     = true
}
