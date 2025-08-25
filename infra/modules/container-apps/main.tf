# =============================================================================
# Azure Container Apps Module - Backend Only
# =============================================================================
# This module creates Azure Container Apps Environment with Consumption workload
# and a backend Container App for API services. Frontend remains in App Service.

# -----------------------------------------------------------------------------
# Container Apps Environment with Consumption Workload Profile
# -----------------------------------------------------------------------------
data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}
resource "azurerm_container_app_environment" "main" {
  name                           = "${var.app_name}-${var.app_env}-containerenv"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.container_apps_subnet_id
  internal_load_balancer_enabled = true # Enable internal load balancer for private access
  # Consumption workload profile (serverless)
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  tags = merge(var.common_tags, {
    Component = "Container Apps Environment"
    Purpose   = "Managed environment for Backend Container Apps"
    Workload  = "Consumption"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}
# Disable public network access if private endpoint is being used
resource "azapi_update_resource" "container_app_env_public_network_access" {
  depends_on = [azurerm_container_app_environment.main]
  type       = "Microsoft.App/managedEnvironments@2024-10-02-preview"
  name       = azurerm_container_app_environment.main.name
  parent_id  = data.azurerm_resource_group.resource_group.id

  body = {
    properties = {
      publicNetworkAccess = "Disabled"
    }
  }
}

# Private Endpoint for Container Apps Environment
# Note: DNS zone association will be automatically managed by Azure Policy
resource "azurerm_private_endpoint" "containerapps" {
  name                = "${var.app_name}-containerapps-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.container_apps_subnet_id

  private_service_connection {
    name                           = "${var.app_name}-containerapps-psc"
    private_connection_resource_id = azurerm_container_app_environment.main.id
    is_manual_connection           = false
  }

  tags = var.common_tags

  # Lifecycle block to ignore DNS zone group changes managed by Azure Policy
  lifecycle {
    ignore_changes = [
      private_dns_zone_group,
      tags
    ]
  }
}

# -----------------------------------------------------------------------------
# Backend Container App - API Service Only
# -----------------------------------------------------------------------------
resource "azurerm_container_app" "backend" {
  name                         = "${var.app_name}-api"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption" # Use Consumption workload profile

  identity {
    type = var.enable_system_assigned_identity ? "SystemAssigned" : "None"
  }

  secret {
    name  = "postgres-password"
    value = var.db_master_password
  }

  secret {
    name  = "appinsights-connection-string"
    value = var.appinsights_connection_string
  }

  secret {
    name  = "appinsights-instrumentation-key"
    value = var.appinsights_instrumentation_key
  }

  template {
    max_replicas                     = var.max_replicas
    min_replicas                     = var.min_replicas
    termination_grace_period_seconds = 10
    container {
      name   = "backend"
      image  = var.backend_image
      cpu    = var.container_cpu
      memory = var.container_memory
      startup_probe {
        transport = "HTTP"
        path      = "/api/health"
        port      = 3000
        timeout   = 5
      }
      readiness_probe {
        transport               = "HTTP"
        path                    = "/api/health"
        port                    = 3000
        timeout                 = 5
        failure_count_threshold = 3
      }
      liveness_probe {
        transport               = "HTTP"
        path                    = "/api/health"
        port                    = 3000
        timeout                 = 5
        failure_count_threshold = 3
      }
      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "PORT"
        value = "3000"
      }

      env {
        name  = "POSTGRES_HOST"
        value = var.postgres_host
      }

      env {
        name  = "POSTGRES_USER"
        value = var.postgresql_admin_username
      }

      env {
        name        = "POSTGRES_PASSWORD"
        secret_name = "postgres-password"
      }

      env {
        name  = "POSTGRES_DATABASE"
        value = var.database_name
      }

      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-connection-string"
      }

      env {
        name        = "APPINSIGHTS_INSTRUMENTATIONKEY"
        secret_name = "appinsights-instrumentation-key"
      }

      # CORS configuration to allow App Service frontend
      env {
        name  = "CORS_ORIGIN"
        value = var.app_service_frontend_url
      }
    }
    http_scale_rule {
      name                = "http-scaling"
      concurrent_requests = "20"
    }
  }

  # Internal ingress for private access from App Service
  ingress {
    external_enabled = false # Internal only - accessible via private endpoint
    target_port      = 3000
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }

    allow_insecure_connections = false
  }

  tags = merge(var.common_tags, {
    Component = "Backend Container App"
    Purpose   = "API application backend"
    Workload  = "Consumption"
  })

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [azurerm_container_app_environment.main]
}
