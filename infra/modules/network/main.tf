# Data block moved to `data.tf` to follow module layout standards
# data "azurerm_virtual_network" "main" moved to data.tf

#------------------------------------------------------------------------------
# Network Security Groups (NSGs)
#
# These NSGs are attached to dedicated subnets created via AzAPI below.
# CIDRs are derived from `var.vnet_address_space` in `locals.tf`.
#
# Notes:
# - Keep priorities unique per direction (Inbound/Outbound) within a given NSG.
# - Prefer Service Tags for Azure platform dependencies where available.
# - For APIM-in-VNet minimum NSG rules, see:
#   https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet#configure-nsg-rules
#------------------------------------------------------------------------------

# NSG for privateendpoints subnet
resource "azurerm_network_security_group" "privateendpoints" {
  name                = "${var.resource_group_name}-pe-nsg"
  location            = var.location
  resource_group_name = var.vnet_resource_group_name

  # Private Endpoints subnet
  # - This subnet hosts private endpoint NICs.
  # PostgreSQL Flexible Server private endpoint access (TCP/5432).
  security_rule {
    name                       = "AllowInboundPostgresFromAppService"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.app_service_subnet_cidr
    destination_address_prefix = local.private_endpoints_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "5432"
  }

  # Container Apps Environment private endpoint access (HTTPS/TCP 443).
  security_rule {
    name                       = "AllowInboundHttpsFromAppService"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.app_service_subnet_cidr
    destination_address_prefix = local.private_endpoints_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "443"
  }

  # PostgreSQL migrations run from ACI/Flyway in the Container Instances subnet.
  security_rule {
    name                       = "AllowInboundPostgresFromContainerInstance"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.container_instance_subnet_cidr
    destination_address_prefix = local.private_endpoints_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "5432"
  }

  # APIM may call Container Apps backends via private networking (HTTPS/TCP 443).
  security_rule {
    name                       = "AllowInboundHttpsFromAPIM"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.apim_subnet_cidr
    destination_address_prefix = local.private_endpoints_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "443"
  }

  # Container Apps backend connects to PostgreSQL over TCP/5432.
  security_rule {
    name                       = "AllowInboundPostgresFromContainerApps"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.container_apps_subnet_cidr
    destination_address_prefix = local.private_endpoints_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "5432"
  }

  # Enforce least-privilege by overriding the NSG default AllowVnetInBound rule.
  # Anything in the VNet not explicitly allowed above is denied.
  security_rule {
    name                       = "DenyInboundFromVirtualNetwork"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = local.private_endpoints_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }
  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# NSG for app service subnet
resource "azurerm_network_security_group" "app_service" {
  name                = "${var.resource_group_name}-as-nsg"
  location            = var.location
  resource_group_name = var.vnet_resource_group_name

  # App Service subnet
  # Intended for App Service VNet integration / delegated subnet.

  # Allow inbound to App Service subnet from private endpoints subnet.
  # Protocol is '*' because private endpoint services may respond over varied ports.
  security_rule {
    name                       = "AllowAppFromPrivateEndpoint"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.private_endpoints_subnet_cidr
    source_port_range          = "*"
    destination_address_prefix = local.app_service_subnet_cidr
    destination_port_range     = "*"
  }

  # Allow outbound from App Service subnet to private endpoints subnet.
  # Protocol is '*' because different private endpoint services can use different ports.
  security_rule {
    name                       = "AllowAppToPrivateEndpoint"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    destination_address_prefix = local.private_endpoints_subnet_cidr
    source_address_prefix      = local.app_service_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }
  # Allow inbound from Container Instances subnet to App Service subnet.
  # Protocol is '*' to allow any required east-west ports.
  security_rule {
    name                       = "AllowAppFromContainerInstance"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.container_instance_subnet_cidr
    source_port_range          = "*"
    destination_address_prefix = local.app_service_subnet_cidr
    destination_port_range     = "*"
  }

  # Allow outbound from App Service subnet to Container Instances subnet.
  # Protocol is '*' to allow any required east-west ports.
  security_rule {
    name                       = "AllowAppToContainerInstance"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    destination_address_prefix = local.container_instance_subnet_cidr
    destination_port_range     = "*"
    source_address_prefix      = local.app_service_subnet_cidr
    source_port_range          = "*"
  }

  # Allow inbound HTTP/HTTPS from the internet to App Service subnet.
  # Use TCP because ports 80/443 are TCP.
  security_rule {
    name                       = "AllowAppFromInternet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = local.app_service_subnet_cidr
    destination_port_ranges    = ["80", "443"]
  }
  # Allow outbound HTTP/HTTPS to the internet from App Service subnet.
  # Use TCP because ports 80/443 are TCP.
  security_rule {
    name                       = "AllowAppOutboundToInternet"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.app_service_subnet_cidr
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
  }

  # Allow outbound to Container Apps (for private backend access)
  # Allow outbound HTTP/HTTPS from App Service subnet to Container Apps subnet.
  # This supports private backend access over standard web ports.
  security_rule {
    name                       = "AllowAppToContainerApps"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.app_service_subnet_cidr
    destination_address_prefix = local.container_apps_subnet_cidr
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
  }

  # Allow inbound response from Container Apps
  # Allow inbound response traffic from Container Apps subnet to App Service subnet.
  # This is symmetrical to AllowAppToContainerApps.
  security_rule {
    name                       = "AllowAppFromContainerApps"
    priority                   = 131
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.container_apps_subnet_cidr
    destination_address_prefix = local.app_service_subnet_cidr
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
  }

  # Allow inbound from APIM
  # Allow inbound from APIM to App Service subnet.
  # Protocol '*' because APIM may call backends on multiple ports (80/443 and app ports).
  security_rule {
    name                       = "AllowInboundFromAPIM"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.apim_subnet_cidr
    destination_address_prefix = local.app_service_subnet_cidr
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "3000-9000"]
  }

  # Allow outbound response to APIM
  # Allow outbound response traffic from App Service subnet back to APIM.
  # Protocol '*' to mirror AllowInboundFromAPIM.
  security_rule {
    name                       = "AllowOutboundToAPIM"
    priority                   = 141
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.app_service_subnet_cidr
    destination_address_prefix = local.apim_subnet_cidr
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "3000-9000"]
  }

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
resource "azurerm_network_security_group" "container_instance" {
  name                = "${var.resource_group_name}-ci-nsg"
  location            = var.location
  resource_group_name = var.vnet_resource_group_name

  # Container Instances subnet
  # Delegated to Microsoft.ContainerInstance/containerGroups.

  # Allow App Service subnet to reach Container Instances subnet (east-west).
  # Protocol/ports are '*' to allow workload-defined ports.
  security_rule {
    name                       = "AllowInboundFromAppService"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.app_service_subnet_cidr
    destination_address_prefix = local.container_instance_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  # Allow return traffic from Container Instances subnet back to App Service subnet.
  # Protocol/ports are '*' to mirror the inbound allow above.
  security_rule {
    name                       = "AllowOutboundToAppService"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    destination_address_prefix = local.app_service_subnet_cidr
    source_address_prefix      = local.container_instance_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  # Allow inbound from Private Endpoints subnet to Container Instances subnet
  # Allow Private Endpoints subnet to reach Container Instances subnet.
  # Protocol/ports are '*' because the consuming service may use different ports.
  security_rule {
    name                       = "AllowInboundFromPrivateEndpoint"
    priority                   = 106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.private_endpoints_subnet_cidr
    destination_address_prefix = local.container_instance_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  # Allow outbound to Private Endpoints subnet from Container Instances subnet
  # Allow Container Instances subnet to reach Private Endpoints subnet.
  # Protocol/ports are '*' because private endpoints can back multiple services.
  security_rule {
    name                       = "AllowOutboundToPrivateEndpoint"
    priority                   = 107
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.container_instance_subnet_cidr
    destination_address_prefix = local.private_endpoints_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }
  # Allow inbound HTTP/HTTPS from the internet (only if the ACI workload is public).
  # Use TCP because ports 80/443 are TCP.
  security_rule {
    name                       = "AllowInboundFromInternet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_address_prefix = local.container_instance_subnet_cidr
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
  }

  # Allow outbound HTTP/HTTPS to the internet (e.g., package feeds, external APIs).
  # Use TCP because ports 80/443 are TCP.
  security_rule {
    name                       = "AllowOutboundToInternet"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_address_prefix = "*"
    source_address_prefix      = local.container_instance_subnet_cidr
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
  }
  # Allow Container Apps subnet to reach Container Instances subnet.
  # Protocol/ports are '*' to allow workload-defined ports.
  security_rule {
    name                       = "AllowInboundFromContainerApps"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.container_apps_subnet_cidr
    destination_address_prefix = local.container_instance_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  # Allow Container Instances subnet to reach Container Apps subnet.
  # Protocol/ports are '*' to allow workload-defined ports.
  security_rule {
    name                       = "AllowOutboundToContainerApps"
    priority                   = 140
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    destination_address_prefix = local.container_apps_subnet_cidr
    source_address_prefix      = local.container_instance_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }
  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# NSG for Container Apps subnet
resource "azurerm_network_security_group" "container_apps" {
  name                = "${var.resource_group_name}-ca-nsg"
  location            = var.location
  resource_group_name = var.vnet_resource_group_name

  # Container Apps subnet
  # Delegated to Microsoft.App/environments.

  # Allow Container Apps management traffic (required by Azure Container Apps)
  # Allow platform-managed traffic for Container Apps environment.
  # Protocol/ports are '*' because platform requirements vary by feature.
  security_rule {
    name                       = "AllowContainerAppsManagement"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = local.container_apps_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  # Allow HTTPS traffic from internet (for public ingress)
  # Allow public HTTPS ingress to Container Apps environment (only if using public ingress).
  # Use TCP because 443 is TCP.
  security_rule {
    name                       = "AllowHTTPSFromInternet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_address_prefix = local.container_apps_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "443"
  }

  # Allow HTTP traffic from internet (for public ingress)
  # Allow public HTTP ingress to Container Apps environment (only if using public ingress).
  # Use TCP because 80 is TCP.
  security_rule {
    name                       = "AllowHTTPFromInternet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_address_prefix = local.container_apps_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "80"
  }

  # Allow communication with private endpoints (PostgreSQL)
  # Allow outbound from Container Apps subnet to Private Endpoints subnet (e.g., PostgreSQL).
  # Protocol/ports are '*' because private endpoints can back multiple services.
  security_rule {
    name                       = "AllowOutboundToPrivateEndpoints"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.container_apps_subnet_cidr
    destination_address_prefix = local.private_endpoints_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }
  # Allow inbound response traffic from Private Endpoints subnet back to Container Apps subnet.
  # Protocol/ports are '*' to mirror the outbound allow above.
  security_rule {
    name                       = "AllowInboundFromPrivateEndpoints"
    priority                   = 131
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.private_endpoints_subnet_cidr
    destination_address_prefix = local.container_apps_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  # Allow inbound traffic from App Service (for private backend access)
  # Allow inbound from App Service subnet to Container Apps subnet (private backend access).
  # Protocol/ports are '*' because workload ports can vary.
  security_rule {
    name                       = "AllowInboundFromAppService"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.app_service_subnet_cidr
    destination_address_prefix = local.container_apps_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  # Allow outbound response to App Service
  # Allow outbound response traffic from Container Apps subnet back to App Service subnet.
  # Protocol/ports are '*' to mirror the inbound allow above.
  security_rule {
    name                       = "AllowOutboundToAppService"
    priority                   = 141
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.container_apps_subnet_cidr
    destination_address_prefix = local.app_service_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  # Allow outbound internet access (for Container Registry, monitoring, etc.)
  # Allow outbound internet access (image pulls, monitoring, control plane dependencies).
  # Protocol/ports are '*' because dependencies can include TCP 443 and other services;
  # tighten if you enforce egress via Azure Firewall/UDR and service tags.
  security_rule {
    name                       = "AllowOutboundToInternet"
    priority                   = 142
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.container_apps_subnet_cidr
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
  }
  # Allow inbound from Container Instances subnet to Container Apps subnet.
  # Protocol/ports are '*' because workload-defined ports can vary.
  security_rule {
    name                       = "AllowInboundFromContainerInstance"
    priority                   = 144
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.container_instance_subnet_cidr
    destination_address_prefix = local.container_apps_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  # Allow outbound response to App Service
  # Allow outbound from Container Apps subnet to Container Instances subnet.
  # Protocol/ports are '*' because workload-defined ports can vary.
  security_rule {
    name                       = "AllowOutboundToContainerInstance"
    priority                   = 145
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.container_apps_subnet_cidr
    destination_address_prefix = local.container_instance_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "*"
  }
  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# NSG for APIM subnet
resource "azurerm_network_security_group" "apim" {
  name                = "${var.resource_group_name}-apim-nsg"
  location            = var.location
  resource_group_name = var.vnet_resource_group_name

  # API Management subnet
  # Minimum required NSG rules are documented by Microsoft (see link above).

  # Allow APIM management traffic (required by Azure API Management)
  # Allow APIM management endpoint (control plane) from the ApiManagement service tag.
  security_rule {
    name                       = "AllowAPIMManagement"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = local.apim_subnet_cidr
    source_port_range          = "*"
    destination_port_range     = "3443"
  }

  # Allow Azure Load Balancer
  # Allow Azure infrastructure load balancer health probes (documented requirement).
  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = local.apim_subnet_cidr
    source_port_range          = "*"
    # APIM infrastructure load balancer health probes
    destination_port_range = "6390"
  }

  # Allow HTTPS inbound (for API gateway)
  # Allow client traffic to APIM gateway and developer portal.
  # If you deploy APIM in internal mode only, this may not be needed.
  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_address_prefix = local.apim_subnet_cidr
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
  }

  # Allow outbound to backend services
  # Allow APIM to reach backend services hosted in the App Service subnet.
  # Protocol '*' because APIM backends can use multiple ports.
  security_rule {
    name                       = "AllowOutboundToAppServices"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.apim_subnet_cidr
    destination_address_prefix = local.app_service_subnet_cidr
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "3000-9000"]
  }

  # Allow outbound to storage and SQL
  # Allow APIM dependency on Azure Storage (documented minimum).
  security_rule {
    name                       = "AllowOutboundToStorage"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.apim_subnet_cidr
    destination_address_prefix = "Storage"
    source_port_range          = "*"
    destination_port_range     = "443"
  }

  # Allow outbound to SQL
  # Allow APIM dependency on SQL (documented minimum).
  security_rule {
    name                       = "AllowOutboundToSQL"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.apim_subnet_cidr
    destination_address_prefix = "Sql"
    source_port_range          = "*"
    destination_port_range     = "1433"
  }

  # Access to Azure Key Vault for APIM certificates/secrets (recommended minimum).
  # Allow APIM dependency on Azure Key Vault (documented minimum).
  security_rule {
    name                       = "AllowOutboundToAzureKeyVault"
    priority                   = 121
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.apim_subnet_cidr
    destination_address_prefix = "AzureKeyVault"
    source_port_range          = "*"
    destination_port_range     = "443"
  }

  # Publish diagnostics/metrics to Azure Monitor (recommended minimum).
  # Allow APIM to publish metrics/diagnostics to Azure Monitor (documented minimum).
  security_rule {
    name                       = "AllowOutboundToAzureMonitor"
    priority                   = 122
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.apim_subnet_cidr
    destination_address_prefix = "AzureMonitor"
    source_port_range          = "*"
    destination_port_ranges    = ["1886", "443"]
  }

  # Allow outbound internet access
  # Allow minimal outbound to Internet for certificate validation (documented minimum).
  security_rule {
    name                       = "AllowOutboundToInternet"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.apim_subnet_cidr
    destination_address_prefix = "*"
    source_port_range          = "*"
    # Microsoft documents TCP/80 as the minimum Internet egress needed for
    # certificate validation and certain management operations.
    destination_port_range = "80"
  }
  # Allow inbound from Container Apps
  # Allow APIM to receive calls from Container Apps (if Container Apps are used as backends).
  # Protocol '*' because backends can use multiple ports.
  security_rule {
    name                       = "AllowInboundFromContainerApps"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.container_apps_subnet_cidr
    destination_address_prefix = local.apim_subnet_cidr
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "3000-9000"]
  }

  # Allow outbound to Container Apps
  # Allow APIM to call Container Apps backends.
  # Protocol '*' because backends can use multiple ports.
  security_rule {
    name                       = "AllowOutboundToContainerApps"
    priority                   = 141
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = local.apim_subnet_cidr
    destination_address_prefix = local.container_apps_subnet_cidr
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "3000-9000"]
  }

  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# Subnets
resource "azapi_resource" "privateendpoints_subnet" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2023-04-01"
  name      = var.private_endpoint_subnet_name
  parent_id = data.azurerm_virtual_network.main.id
  locks     = [data.azurerm_virtual_network.main.id]
  body = {
    properties = {
      addressPrefix = local.private_endpoints_subnet_cidr
      networkSecurityGroup = {
        id = azurerm_network_security_group.privateendpoints.id
      }
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "app_service_subnet" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2023-04-01"
  name      = var.apps_service_subnet_name
  parent_id = data.azurerm_virtual_network.main.id
  locks     = [data.azurerm_virtual_network.main.id]
  body = {
    properties = {
      addressPrefix = local.app_service_subnet_cidr
      networkSecurityGroup = {
        id = azurerm_network_security_group.app_service.id
      }
      delegations = [
        {
          name = "app-service-delegation"
          properties = {
            serviceName = "Microsoft.Web/serverFarms"
          }
        }
      ]
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "container_instance_subnet" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2023-04-01"
  name      = var.container_instance_subnet_name
  parent_id = data.azurerm_virtual_network.main.id
  locks     = [data.azurerm_virtual_network.main.id]
  body = {
    properties = {
      addressPrefix = local.container_instance_subnet_cidr
      networkSecurityGroup = {
        id = azurerm_network_security_group.container_instance.id
      }
      delegations = [
        {
          name = "aci-delegation"
          properties = {
            serviceName = "Microsoft.ContainerInstance/containerGroups"
          }
        }
      ]
    }
  }
  response_export_values = ["*"]
}


# Container Apps subnet for Container Apps Environment
resource "azapi_resource" "container_apps_subnet" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2023-04-01"
  name      = var.container_apps_subnet_name
  parent_id = data.azurerm_virtual_network.main.id
  locks     = [data.azurerm_virtual_network.main.id]
  body = {
    properties = {
      addressPrefix = local.container_apps_subnet_cidr
      networkSecurityGroup = {
        id = azurerm_network_security_group.container_apps.id
      }
      delegations = [
        {
          name = "container-apps-delegation"
          properties = {
            serviceName = "Microsoft.App/environments"
          }
        }
      ]
    }
  }
  response_export_values = ["*"]
}

# APIM subnet for API Management
resource "azapi_resource" "apim_subnet" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2023-04-01"
  name      = var.apim_subnet_name
  parent_id = data.azurerm_virtual_network.main.id
  locks     = [data.azurerm_virtual_network.main.id]
  body = {
    properties = {
      addressPrefix = local.apim_subnet_cidr
      networkSecurityGroup = {
        id = azurerm_network_security_group.apim.id
      }
      delegations = [
        {
          name = "apim-delegation"
          properties = {
            serviceName = "Microsoft.Web/serverFarms"
          }
        }
      ]
    }
  }
  response_export_values = ["*"]
}
