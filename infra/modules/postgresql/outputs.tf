output "database_name" {
  description = "The name of the PostgreSQL database."
  value       = azurerm_postgresql_flexible_server_database.postgres_database.name
}

output "postgres_host" {
  description = "The FQDN of the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.postgresql.fqdn
}

output "db_master_password" {
  description = "The password for the PostgreSQL admin user."
  value       = var.postgresql_admin_password
  sensitive   = true
}
