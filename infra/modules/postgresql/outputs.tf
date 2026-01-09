output "database_name" {
  description = "The name of the PostgreSQL database."
  value       = var.database_name
}

output "postgres_host" {
  description = "The FQDN of the PostgreSQL server."
  value       = module.postgresql.fqdn
}

output "db_master_password" {
  description = "The password for the PostgreSQL admin user."
  value       = random_password.postgres_master_password.result
  sensitive   = true
}
