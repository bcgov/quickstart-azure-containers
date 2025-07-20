# App Service Plan for container-based applications
resource "azurerm_service_plan" "backend" {
  name                = "${var.app_name}-backend-asp"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku_name_backend
  depends_on          = [azurerm_resource_group.main]

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}


# App Service for API backend with container
resource "azurerm_linux_web_app" "backend" {
  name                = "${var.repo_name}-${var.app_env}-api"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.backend.id

  # VNet integration for secure communication
  virtual_network_subnet_id = data.azurerm_subnet.app_service.id

  # Enable HTTPS only
  https_only = true

  # Enable managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_service_identity.id]
  }

  site_config {
    always_on                                     = true
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.app_service_identity.client_id

    # Security - Use latest TLS version
    minimum_tls_version = "1.3"

    # Health check configuration
    health_check_path                 = "/api/health"
    health_check_eviction_time_in_min = 2

    # Application stack for container
    application_stack {
      docker_image_name   = var.api_image
      docker_registry_url = var.create_container_registry ? "https://${azurerm_container_registry.main[0].login_server}" : "https://ghcr.io"
    }

    # Configure for container deployment
    ftps_state = "Disabled"

    # CORS configuration for direct access
    cors {
      allowed_origins     = ["*"] # Allow all origins - customize as needed for production
      support_credentials = false
    }
    
    dynamic "ip_restriction" {
      for_each = split(",", azurerm_linux_web_app.frontend.possible_outbound_ip_addresses)
      content {
        ip_address = ip_restriction.value != "" ? "${ip_restriction.value}/32" : null
        virtual_network_subnet_id = ip_restriction.value == "" ? data.azurerm_subnet.app_service.id : null
        service_tag = ip_restriction.value == "" ? "AppService" : null
        action     = "Allow"
        name       = "AFOutbound${replace(ip_restriction.value, ".", "")}"
        priority   = 100
      }
    }
    ip_restriction {
      name        = "DenyAll"
      action      = "Deny"
      priority    = 500
      ip_address  = "0.0.0.0/0"
      description = "Deny all other traffic"
    }
    ip_restriction_default_action = "Deny"
  }

  # Application settings
  app_settings = {
    "NODE_ENV"                              = var.node_env
    "PORT"                                  = "80"
    "WEBSITES_PORT"                         = "3000"
    "DOCKER_ENABLE_CI"                      = "true"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key

    # Database configuration using direct variables
    "POSTGRES_HOST"                       = azurerm_postgresql_flexible_server.postgresql.fqdn
    "POSTGRES_USER"                       = var.postgresql_admin_username
    "POSTGRES_PASSWORD"                   = var.db_master_password
    "POSTGRES_DATABASE"                   = var.database_name
    "WEBSITE_SKIP_RUNNING_KUDUAGENT"      = "false"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITE_ENABLE_SYNC_UPDATE_SITE"     = "1"
  }

  # Logs configuration
  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 100
      }
    }
  }
  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
  depends_on = [azurerm_linux_web_app.frontend]
}




# Storage Account for CloudBeaver workspace persistence
resource "azurerm_storage_account" "cloudbeaver" {
  count                    = var.enable_psql_sidecar ? 1 : 0
  name                     = "${replace(var.app_name, "-", "")}cbstorage"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Landing Zone security requirements
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}

# File Share for CloudBeaver workspace
resource "azurerm_storage_share" "cloudbeaver_workspace" {
  count              = var.enable_psql_sidecar ? 1 : 0
  name               = "${var.app_name}-cb-workspace"
  storage_account_id = azurerm_storage_account.cloudbeaver[0].id
  quota              = 10 # 10 GB quota
}

# Private endpoint for Storage Account
resource "azurerm_private_endpoint" "cloudbeaver_storage" {
  count               = var.enable_psql_sidecar ? 1 : 0
  name                = "${var.app_name}-cb-storage-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "${var.app_name}-cb-storage-psc"
    private_connection_resource_id = azurerm_storage_account.cloudbeaver[0].id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags,
      # Ignore private DNS zone group as it's managed by Azure Policy
      private_dns_zone_group
    ]
  }
}

# Random strings for CloudBeaver admin credentials
resource "random_string" "cloudbeaver_admin_name" {
  count   = var.enable_psql_sidecar ? 1 : 0
  length  = 12
  special = false
  upper   = false
  numeric = true
}

resource "random_password" "cloudbeaver_admin_password" {
  count   = var.enable_psql_sidecar ? 1 : 0
  length  = 16
  special = true
}

# App Service for CloudBeaver database management
resource "azurerm_linux_web_app" "psql_sidecar" {
  count               = var.enable_psql_sidecar ? 1 : 0
  name                = "${var.repo_name}-${var.app_env}-cloudbeaver"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.backend.id

  # VNet integration for secure communication
  virtual_network_subnet_id = data.azurerm_subnet.app_service.id

  # Enable HTTPS only
  https_only = true

  # Enable managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_service_identity.id]
  }

  site_config {
    always_on                                     = true
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.app_service_identity.client_id

    # Security - Use latest TLS version
    minimum_tls_version = "1.3"

    # Health check configuration
    health_check_path                 = "/"
    health_check_eviction_time_in_min = 10

    # Application stack for CloudBeaver container
    application_stack {
      docker_image_name   = "dbeaver/cloudbeaver:latest"
      docker_registry_url = "https://index.docker.io"
    }

    # Configure for container deployment
    ftps_state = "Disabled"

    # Startup command to mount Azure Files and start CloudBeaver
    app_command_line = "/bin/sh -c 'mkdir -p /opt/cloudbeaver/workspace && echo \"CloudBeaver starting with persistent workspace...\" && /opt/cloudbeaver/run-server.sh'"
  }

  # Application settings for CloudBeaver
  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = "false"
    "DOCKER_ENABLE_CI"                      = "true"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key

    # CloudBeaver configuration
    "WEBSITES_PORT" = "8978"
    "PORT"          = "8978"

    # Pre-configure PostgreSQL connection via environment variables
    "CB_SERVER_NAME"    = var.app_name
    "CB_SERVER_URL"     = "https://${var.app_name}-cloudbeaver-app.azurewebsites.net"
    "CB_ADMIN_NAME"     = "${random_string.cloudbeaver_admin_name[0].result}"
    "CB_ADMIN_PASSWORD" = random_password.cloudbeaver_admin_password[0].result

    # PostgreSQL connection configuration for pre-configuration
    "POSTGRES_HOST"     = azurerm_postgresql_flexible_server.postgresql.fqdn
    "POSTGRES_USER"     = var.postgresql_admin_username
    "POSTGRES_PASSWORD" = var.db_master_password
    "POSTGRES_DATABASE" = var.database_name
    "POSTGRES_PORT"     = "5432"

    # CloudBeaver specific settings
    "CB_LOCAL_HOST_ACCESS"        = "false"
    "CB_ENABLE_REVERSEPROXY_AUTH" = "false"
    "CB_DEV_MODE"                 = "false"

    # Azure Files mount configuration for persistent workspace
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "AZURE_STORAGE_CONNECTION_STRING"     = azurerm_storage_account.cloudbeaver[0].primary_connection_string
    "WORKSPACE_PATH"                      = "/opt/cloudbeaver/workspace"
  }

  # Logs configuration
  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 100
      }
    }
  }

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}




resource "azurerm_monitor_diagnostic_setting" "backend_diagnostics" {
  name                       = "${var.app_name}-backend-diagnostics"
  target_resource_id         = azurerm_linux_web_app.backend.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }
}


