resource "azurerm_key_vault" "main" {
  name                = "${var.app_name}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = lower(var.key_vault_sku_name)

  rbac_authorization_enabled    = var.key_vault_enable_rbac_authorization
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  purge_protection_enabled      = var.key_vault_purge_protection_enabled
  public_network_access_enabled = false

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "${var.app_name}-kv-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.app_name}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = var.common_tags

  lifecycle {
    ignore_changes = [
      private_dns_zone_group,
      tags
    ]
  }
}

resource "random_password" "postgres_admin" {
  length  = var.postgres_password_length
  special = true
}

resource "azurerm_key_vault_secret" "postgres_admin_password" {
  name         = var.postgres_password_secret_name
  value        = random_password.postgres_admin.result
  key_vault_id = azurerm_key_vault.main.id

  # Required by BC Gov landing zone policy (max secret validity period)
  expiration_date = timeadd(timestamp(), format("%dh", var.postgres_password_validity_days * 24))

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [azurerm_private_endpoint.key_vault]
}
