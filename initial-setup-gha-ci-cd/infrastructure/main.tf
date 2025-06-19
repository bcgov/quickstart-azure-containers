resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}
# Register required Azure resource providers app and storage and cosmosdb
resource "azurerm_resource_provider_registration" "app" {
  name = "Microsoft.App"
}

resource "azurerm_resource_provider_registration" "storage" {
  name = "Microsoft.Storage"
}



module "github_runners" {
  source  = "Azure/avm-ptn-cicd-agents-and-runners/azurerm"
  version = "~> 0.3"

  location = azurerm_resource_group.rg.location
  postfix  = var.postfix

  compute_types                                    = var.compute_types
  container_instance_count                         = var.container_instance_count
  container_app_infrastructure_resource_group_name = local.container_app_infrastructure_resource_group_name

  resource_group_creation_enabled = false
  resource_group_name             = azurerm_resource_group.rg.name

  version_control_system_type                  = var.version_control_system_type
  version_control_system_organization          = var.version_control_system_organization
  version_control_system_repository            = var.version_control_system_repository
  version_control_system_personal_access_token = var.github_personal_access_token

  virtual_network_creation_enabled = false
  virtual_network_id               = local.virtual_network_id

  container_app_subnet_id = azapi_resource.github_runners_container_app_subnet.id

  container_instance_subnet_id   = azapi_resource.github_runners_container_instance_subnet.id
  container_instance_subnet_name = var.container_instance_subnet_name

  container_registry_private_dns_zone_creation_enabled = false

  nat_gateway_creation_enabled = false
  public_ip_creation_enabled   = false

  container_registry_creation_enabled = true
  use_private_networking              = true
  use_default_container_image         = true

  container_registry_private_endpoint_subnet_id   = azapi_resource.github_runners_private_endpoint_subnet.id
  container_registry_private_endpoint_subnet_name = var.private_endpoint_subnet_name

  tags = var.tags
  depends_on = [
    azurerm_resource_provider_registration.app,
    azurerm_resource_provider_registration.storage,
  ]
}
# Create an Azure Storage Account
resource "azurerm_storage_account" "runner_storage" {
  name                              = var.tf_storage_account_name
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  public_network_access_enabled     = false
  https_traffic_only_enabled        = true
  infrastructure_encryption_enabled = true
  tags = var.tags
  access_tier              = "Cool"
  network_rules {
    default_action = "Deny"
    bypass         = ["None"]

  }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# Create a Cosmos DB Account (NoSQL)
resource "azurerm_cosmosdb_account" "runner_cosmos" {
  name                              = "runner-cosmos-tflock"
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.rg.name
  minimal_tls_version               = "Tls12"
  offer_type                        = "Standard"
  kind                              = "GlobalDocumentDB"
  public_network_access_enabled     = false
  is_virtual_network_filter_enabled = true

  virtual_network_rule {
    id = azapi_resource.github_runners_container_app_subnet.id
  }

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

  tags = var.tags
}

# Create a private endpoint for the Cosmos DB account
resource "azurerm_private_endpoint" "cosmos_private_endpoint" {
  name                = "cosmos-private-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azapi_resource.github_runners_private_endpoint_subnet.id

  private_service_connection {
    name                           = "cosmos-private-connection"
    private_connection_resource_id = azurerm_cosmosdb_account.runner_cosmos.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  tags = var.tags
}

# Create a Cosmos DB Database
resource "azurerm_cosmosdb_sql_database" "runner_db" {
  name                = "runner-database"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.runner_cosmos.name
}

# Assign Storage Blob Data Contributor role to the runner
resource "azurerm_role_assignment" "runner_storage_contributor" {
  scope                = azurerm_storage_account.runner_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.github_runners.user_assigned_managed_identity_principal_id
}

# Assign Cosmos DB Data Contributor role to the runner
resource "azurerm_role_assignment" "runner_cosmos_contributor" {
  scope                = azurerm_cosmosdb_account.runner_cosmos.id
  role_definition_name = "Cosmos DB Account Reader Role"
  principal_id         = module.github_runners.user_assigned_managed_identity_principal_id
}
