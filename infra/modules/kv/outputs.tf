output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "postgres_admin_password" {
  description = "Generated PostgreSQL admin password"
  value       = random_password.postgres_admin.result
  sensitive   = true
}

output "postgres_admin_password_secret_uri" {
  description = "Key Vault secret ID without version (tracks latest version)"
  value       = azurerm_key_vault_secret.postgres_admin_password.versionless_id
}
