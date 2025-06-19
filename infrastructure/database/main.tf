terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 3.0"
        }
    }
}

provider "azurerm" {
    features {
        key_vault {
            purge_soft_delete_on_destroy = true
        }
    }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "postgres_rg" {
    name     = "rg-postgres-flexible"
    location = "canadacentral"
}

resource "azurerm_key_vault" "postgres_kv" {
    name                        = "kv-postgres-${random_string.random.result}"
    location                    = azurerm_resource_group.postgres_rg.location
    resource_group_name         = azurerm_resource_group.postgres_rg.name
    enabled_for_disk_encryption = true
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    soft_delete_retention_days  = 7
    purge_protection_enabled    = false
    sku_name                    = "standard"

    access_policy {
        tenant_id = data.azurerm_client_config.current.tenant_id
        object_id = data.azurerm_client_config.current.object_id

        key_permissions = [
            "Get", "List", "Create"
        ]

        secret_permissions = [
            "Get", "List", "Set", "Delete"
        ]
    }
}

resource "random_string" "random" {
    length  = 6
    special = false
    upper   = false
}

resource "random_password" "postgres_password" {
    length           = 16
    special          = true
    override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "postgres_password" {
    name         = "postgres-admin-password"
    value        = random_password.postgres_password.result
    key_vault_id = azurerm_key_vault.postgres_kv.id
}

resource "azurerm_virtual_network" "postgres_vnet" {
    name                = "vnet-postgres"
    location            = azurerm_resource_group.postgres_rg.location
    resource_group_name = azurerm_resource_group.postgres_rg.name
    address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "postgres_subnet" {
    name                 = "subnet-postgres"
    resource_group_name  = azurerm_resource_group.postgres_rg.name
    virtual_network_name = azurerm_virtual_network.postgres_vnet.name
    address_prefixes     = ["10.0.2.0/24"]
    service_endpoints    = ["Microsoft.Storage"]
    delegation {
        name = "fs"
        service_delegation {
            name = "Microsoft.DBforPostgreSQL/flexibleServers"
            actions = [
                "Microsoft.Network/virtualNetworks/subnets/join/action",
            ]
        }
    }
}

resource "azurerm_private_dns_zone" "postgres_dns" {
    name                = "postgres.private.postgres.database.azure.com"
    resource_group_name = azurerm_resource_group.postgres_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_link" {
    name                  = "postgres-dns-link"
    private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
    virtual_network_id    = azurerm_virtual_network.postgres_vnet.id
    resource_group_name   = azurerm_resource_group.postgres_rg.name
}

resource "azurerm_postgresql_flexible_server" "postgres" {
    name                   = "postgres-flexible-server"
    resource_group_name    = azurerm_resource_group.postgres_rg.name
    location               = azurerm_resource_group.postgres_rg.location
    version                = "14"
    delegated_subnet_id    = azurerm_subnet.postgres_subnet.id
    private_dns_zone_id    = azurerm_private_dns_zone.postgres_dns.id
    administrator_login    = "psqladmin"
    administrator_password = azurerm_key_vault_secret.postgres_password.value
    zone                   = "1"
    storage_mb             = 32768
    sku_name               = "GP_Standard_D2s_v3"
    backup_retention_days  = 7

    depends_on = [
        azurerm_private_dns_zone_virtual_network_link.postgres_dns_link
    ]
}

resource "azurerm_postgresql_flexible_server_database" "postgres_db" {
    name      = "exampledb"
    server_id = azurerm_postgresql_flexible_server.postgres.id
    charset   = "UTF8"
    collation = "en_US.utf8"
}

# Firewall rule to allow Azure services access
resource "azurerm_postgresql_flexible_server_firewall_rule" "postgres_fw" {
    name             = "AllowAzureServices"
    server_id        = azurerm_postgresql_flexible_server.postgres.id
    start_ip_address = "0.0.0.0"
    end_ip_address   = "0.0.0.0"
}

output "postgres_server_fqdn" {
    value = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "key_vault_name" {
    value = azurerm_key_vault.postgres_kv.name
}