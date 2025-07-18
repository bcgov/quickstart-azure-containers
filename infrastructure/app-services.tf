

# Azure App Services for API backend with Front Door

# Data source for existing virtual network
data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

# Data source for private endpoint subnet
data "azurerm_subnet" "private_endpoint" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = var.vnet_resource_group_name
  depends_on           = [azapi_resource.privateendpoints_subnet]
}

# Data source for existing subnet for Container Apps/App Services
data "azurerm_subnet" "app_service" {
  name                 = var.apps_service_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = var.vnet_resource_group_name
  depends_on           = [azapi_resource.app_service_subnet]
}

# Data source for existing web subnet
data "azurerm_subnet" "web" {
  name                 = var.web_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = var.vnet_resource_group_name
  depends_on           = [azapi_resource.web_subnet]
}



# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.app_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name # the database module creates the resource group
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}

# Application Insights for enhanced monitoring and logging
resource "azurerm_application_insights" "main" {
  name                = "${var.app_name}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name # the database module creates the resource group
  application_type    = "other"
  workspace_id        = azurerm_log_analytics_workspace.main.id

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "container_apps" {
  name                = "${var.app_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name # the database module creates the resource group

  tags = var.common_tags
}

# Container Registry (if using private registry) - Landing Zone compliant
resource "azurerm_container_registry" "main" {
  count               = var.create_container_registry ? 1 : 0
  name                = "${replace(var.app_name, "-", "")}acr"
  resource_group_name = var.resource_group_name # the database module creates the resource group
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false

  # Azure Landing Zone security requirements
  public_network_access_enabled = false
  tags                          = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}

# Grant App Services access to Container Registry
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.create_container_registry ? 1 : 0
  scope                = azurerm_container_registry.main[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.container_apps.principal_id
}

# Private endpoint for Container Registry (Landing Zone compliance)
resource "azurerm_private_endpoint" "container_registry" {
  count               = var.create_container_registry ? 1 : 0
  name                = "${var.app_name}-acr-pe"
  location            = var.location
  resource_group_name = var.resource_group_name # the database module creates the resource group
  subnet_id           = data.azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "${var.app_name}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.main[0].id
    subresource_names              = ["registry"]
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

# App Service Plan for container-based applications
resource "azurerm_service_plan" "main" {
  name                = "${var.app_name}-asp"
  resource_group_name = var.resource_group_name # the database module creates the resource group
  location            = var.location
  os_type             = "Linux"
  sku_name            = "S1" # Standard tier to support deployment slots


  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}


# App Service for API backend with container
resource "azurerm_linux_web_app" "api" {
  name                = "${var.repo_name}-${var.app_env}-api"
  resource_group_name = var.resource_group_name # the database module creates the resource group
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  # VNet integration for secure communication
  virtual_network_subnet_id = data.azurerm_subnet.app_service.id

  # Enable HTTPS only
  https_only = true

  # Enable managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_apps.id]
  }

  site_config {
    always_on                                     = true
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.container_apps.client_id

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
  }

  # Application settings
  app_settings = {
    "NODE_ENV"                              = var.node_env
    "PORT"                                  = "80"
    "WEBSITES_PORT"                         = "3000"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = "false"
    "DOCKER_ENABLE_CI"                      = "true"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key

    # Database configuration using direct variables
    "POSTGRES_HOST"                       = azurerm_postgresql_flexible_server.main.fqdn
    "POSTGRES_USER"                       = var.postgresql_admin_username
    "POSTGRES_PASSWORD"                   = var.postgresql_admin_password
    "POSTGRES_DATABASE"                   = var.database_name
    "WEBSITE_SKIP_RUNNING_KUDUAGENT"      = "false"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "true"
  }
  storage_account {
    name         = "flywaywebjobmount"
    account_name = azurerm_storage_account.flyway_webjob.name
    access_key   = azurerm_storage_account.flyway_webjob.primary_access_key
    share_name   = azurerm_storage_share.flyway_webjob.name
    mount_path   = "/mnt/flywaydata"
    type         = "AzureFiles"

  }

  # Logs configuration
  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    application_logs {
      file_system_level = "Information"
    }

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

# App Service Plan for frontend application
resource "azurerm_service_plan" "frontend" {
  name                = "${var.app_name}-frontend-asp"
  resource_group_name = var.resource_group_name # the database module creates the resource group
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1" # Basic tier

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      # Ignore tags to allow management via Azure Policy
      tags
    ]
  }
}

# App Service for Frontend with container
resource "azurerm_linux_web_app" "frontend" {
  name                = "${var.repo_name}-${var.app_env}-frontend"
  resource_group_name = var.resource_group_name # the database module creates the resource group
  location            = var.location
  service_plan_id     = azurerm_service_plan.frontend.id

  # VNet integration for secure communication - same subnet as API
  virtual_network_subnet_id = data.azurerm_subnet.app_service.id

  # Enable HTTPS only
  https_only = true

  # Enable managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_apps.id]
  }

  site_config {
    always_on                                     = true
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.container_apps.client_id

    # Security - Use latest TLS version
    minimum_tls_version = "1.3"

    # Health check configuration
    health_check_path                 = "/"
    health_check_eviction_time_in_min = 2

    # Application stack for container
    application_stack {
      docker_image_name   = var.frontend_image
      docker_registry_url = "https://ghcr.io"
    }

    # Configure for container deployment
    ftps_state = "Disabled"

    # CORS configuration for frontend
    cors {
      allowed_origins     = ["*"] # Allow all origins for frontend
      support_credentials = false
    }
  }

  # Application settings for frontend
  app_settings = {
    PORT                                    = "80"
    "WEBSITES_PORT"                         = "3000"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = "false"
    "DOCKER_ENABLE_CI"                      = "true"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key

    # Backend URL for frontend to communicate with API
    "VITE_BACKEND_URL" = "https://${azurerm_linux_web_app.api.default_hostname}"
    "LOG_LEVEL"        = "info" # Default log level for frontend
  }

  # Logs configuration
  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    application_logs {
      file_system_level = "Information"
    }

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

# Storage Account for CloudBeaver workspace persistence
resource "azurerm_storage_account" "cloudbeaver" {
  count                    = var.enable_psql_sidecar ? 1 : 0
  name                     = "${replace(var.app_name, "-", "")}cbstorage"
  resource_group_name      = var.resource_group_name # the database module creates the resource group
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
  resource_group_name = var.resource_group_name # the database module creates the resource group
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
  resource_group_name = var.resource_group_name # the database module creates the resource group
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  # VNet integration for secure communication
  virtual_network_subnet_id = data.azurerm_subnet.app_service.id

  # Enable HTTPS only
  https_only = true

  # Enable managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_apps.id]
  }

  site_config {
    always_on                                     = true
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.container_apps.client_id

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
    "POSTGRES_HOST"     = azurerm_postgresql_flexible_server.main.fqdn
    "POSTGRES_USER"     = var.postgresql_admin_username
    "POSTGRES_PASSWORD" = var.postgresql_admin_password
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

    application_logs {
      file_system_level = "Information"
    }

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


# Azure Front Door Profile - Premium for private endpoint connectivity (commented out - removed Front Door)
# resource "azurerm_cdn_frontdoor_profile" "main" {
#   name                = "${var.app_name}-frontdoor"
#   resource_group_name = azurerm_resource_group.api.name
#   sku_name            = "Premium_AzureFrontDoor"
#
#   tags = var.common_tags
#   lifecycle {
#     ignore_changes = [
#       # Ignore tags to allow management via Azure Policy
#       tags
#     ]
#   }
# }

# Front Door Endpoint (commented out - removed Front Door)
# resource "azurerm_cdn_frontdoor_endpoint" "main" {
#   name                     = "${var.app_name}-endpoint"
#   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
#
#   tags = var.common_tags
# }

# Front Door Origin Group (commented out - removed Front Door)
# resource "azurerm_cdn_frontdoor_origin_group" "main" {
#   name                     = "${var.app_name}-origin-group"
#   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
#   session_affinity_enabled = false
#
#   restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 10
#
#   health_probe {
#     interval_in_seconds = 100
#     path                = "/api/health"
#     protocol            = "Https"
#     request_type        = "GET"
#   }
#
#   load_balancing {
#     additional_latency_in_milliseconds = 50
#     sample_size                        = 4
#     successful_samples_required        = 3
#   }
# }

# Front Door Origin with Private Link (commented out - removed Front Door)
# resource "azurerm_cdn_frontdoor_origin" "main" {
#   name                          = "${var.app_name}-origin"
#   cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
#   enabled                       = true
#
#   certificate_name_check_enabled = true
#   host_name                      = azurerm_linux_web_app.api.default_hostname
#   http_port                      = 80
#   https_port                     = 443
#   origin_host_header             = azurerm_linux_web_app.api.default_hostname
#   priority                       = 1
#   weight                         = 1000
#
#   # Private Link configuration for App Service
#   private_link {
#     request_message        = "Request access for Front Door to App Service"
#     target_type           = "sites"
#     location              = var.location
#     private_link_target_id = azurerm_linux_web_app.api.id
#   }
# }

# Front Door Custom Domain (commented out - removed Front Door)
# resource "azurerm_cdn_frontdoor_custom_domain" "main" {
#   count                    = var.custom_domain_name != "" ? 1 : 0
#   name                     = "${replace(var.custom_domain_name, ".", "-")}-domain"
#   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
#   dns_zone_id              = var.dns_zone_id
#   host_name                = var.custom_domain_name
#
#   tls {
#     certificate_type         = "ManagedCertificate"
#   }
# }

# Front Door Route with Enhanced Security (commented out - removed Front Door)
# resource "azurerm_cdn_frontdoor_route" "main" {
#   name                          = "${var.app_name}-route"
#   cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
#   cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
#   cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.main.id]
#
#   supported_protocols    = ["Http", "Https"]
#   patterns_to_match      = ["/*"]
#   forwarding_protocol    = "HttpsOnly"
#   link_to_default_domain = true
#
#   # Optional: Link to custom domain
#   cdn_frontdoor_custom_domain_ids = var.custom_domain_name != "" ? [azurerm_cdn_frontdoor_custom_domain.main[0].id] : []
#
#   https_redirect_enabled = true
#
#   # Cache configuration for better performance
#   cache {
#     query_string_caching_behavior = "IgnoreQueryString"
#     compression_enabled           = true
#     content_types_to_compress = [
#       "application/eot",
#       "application/font",
#       "application/font-sfnt",
#       "application/javascript",
#       "application/json",
#       "application/opentype",
#       "application/otf",
#       "application/pkcs7-mime",
#       "application/truetype",
#       "application/ttf",
#       "application/vnd.ms-fontobject",
#       "application/xhtml+xml",
#       "application/xml",
#       "application/xml+rss",
#       "application/x-font-opentype",
#       "application/x-font-truetype",
#       "application/x-font-ttf",
#       "application/x-httpd-cgi",
#       "application/x-javascript",
#       "application/x-mpegurl",
#       "application/x-opentype",
#       "application/x-otf",
#       "application/x-perl",
#       "application/x-ttf",
#       "font/eot",
#       "font/ttf",
#       "font/otf",
#       "font/opentype",
#       "image/svg+xml",
#       "text/css",
#       "text/csv",
#       "text/html",
#       "text/javascript",
#       "text/js",
#       "text/plain",
#       "text/richtext",
#       "text/tab-separated-values",
#       "text/xml",
#       "text/x-script",
#       "text/x-component",
#       "text/x-java-source"
#     ]
#   }
# }

# WAF Policy for Front Door Premium (commented out - removed Front Door)
# resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
#   name                = "${replace(var.app_name, "-", "")}fdwaf"
#   resource_group_name = azurerm_resource_group.api.name
#   sku_name            = "Premium_AzureFrontDoor"
#   enabled             = true
#   mode                = "Prevention"
#
#   # Enhanced WAF rules for Premium
#   managed_rule {
#     type    = "Microsoft_DefaultRuleSet"
#     version = "2.1"
#     action  = "Block"
#     
#     # Additional exclusions can be configured here if needed
#     exclusion {
#       match_variable = "RequestHeaderNames"
#       operator       = "Equals"
#       selector       = "x-company-secret-header"
#     }
#   }
#
#   managed_rule {
#     type    = "Microsoft_BotManagerRuleSet"
#     version = "1.0"
#     action  = "Block"
#   }
#
#   # Rate limiting rule (Premium feature)
#   custom_rule {
#     name                           = "RateLimitRule"
#     enabled                        = true
#     priority                       = 1
#     rate_limit_duration_in_minutes = 1
#     rate_limit_threshold           = var.waf_rate_limit_threshold
#     type                           = "RateLimitRule"
#     action                         = "Block"
#
#     match_condition {
#       match_variable     = "RemoteAddr"
#       operator           = "IPMatch"
#       negation_condition = false
#       match_values       = ["0.0.0.0/0"]
#     }
#   }
#
#   # Geo-blocking rule (Premium feature) - Allow only specific countries
#   custom_rule {
#     name     = "GeoBlockingRule"
#     enabled  = true
#     priority = 2
#     type     = "MatchRule"
#     action   = "Block"
#
#     match_condition {
#       match_variable     = "RemoteAddr"
#       operator           = "GeoMatch"
#       negation_condition = true
#       match_values       = var.waf_allowed_countries
#     }
#   }
#
#   tags = var.common_tags
#   lifecycle {
#     ignore_changes = [
#       # Ignore tags to allow management via Azure Policy
#       tags
#     ]
#   }
# }

# Security Policy for Front Door (commented out - removed Front Door)
# resource "azurerm_cdn_frontdoor_security_policy" "main" {
#   name                     = "${var.app_name}-security-policy"
#   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
#
#   security_policies {
#     firewall {
#       cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.id
#
#       association {
#         domain {
#           cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
#         }
#         patterns_to_match = ["/*"]
#       }
#
#       # Optional: Associate with custom domain
#       dynamic "association" {
#         for_each = var.custom_domain_name != "" ? [1] : []
#         content {
#           domain {
#             cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.main[0].id
#           }
#           patterns_to_match = ["/*"]
#         }
#       }
#     }
#   }
# }

# Private Endpoint for App Service (optional, for enhanced security)
resource "azurerm_private_endpoint" "app_service" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.app_name}-app-pe"
  location            = var.location
  resource_group_name = var.resource_group_name # the database module creates the resource group
  subnet_id           = data.azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "${var.app_name}-app-psc"
    private_connection_resource_id = azurerm_linux_web_app.api.id
    subresource_names              = ["sites"]
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

# Auto-scaling settings for App Service Plan
resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "${var.app_name}-autoscale"
  resource_group_name = var.resource_group_name # the database module creates the resource group
  location            = var.location
  target_resource_id  = azurerm_service_plan.main.id

  profile {
    name = "default"

    capacity {
      default = 2
      minimum = 1
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
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

# Diagnostic settings for API App Service (Landing Zone compliance)  
resource "azurerm_monitor_diagnostic_setting" "api_app_service" {
  name                       = "${var.app_name}-api-diagnostics"
  target_resource_id         = azurerm_linux_web_app.api.id
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



# Front Door outputs (commented out - removed Front Door)
# output "front_door_endpoint_url" {
#   description = "The URL of the Front Door endpoint"
#   value       = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}"
# }

# output "front_door_custom_domain_url" {
#   description = "The URL of the custom domain (if configured)"
#   value       = var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : ""
# }

# output "front_door_profile_id" {
#   description = "The ID of the Front Door Profile"
#   value       = azurerm_cdn_frontdoor_profile.main.id
# }

