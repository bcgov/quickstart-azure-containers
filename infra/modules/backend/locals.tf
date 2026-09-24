locals {
  # avm-res-web-site composes linuxFxVersion as DOCKER|<registry-host>/<repository>:<tag>,
  # so a full image reference has to be split back into its three parts.
  api_image_ref   = trimprefix(trimprefix(var.api_image, "https://"), "http://")
  api_image_parts = split("/", local.api_image_ref)
  api_image_has_registry = length(local.api_image_parts) > 1 && (
    strcontains(local.api_image_parts[0], ".") || strcontains(local.api_image_parts[0], ":")
  )
  api_registry_host = (
    local.api_image_has_registry
    ? local.api_image_parts[0]
    : trimprefix(trimprefix(var.container_registry_url, "https://"), "http://")
  )
  api_repository_ref = (
    local.api_image_has_registry
    ? join("/", slice(local.api_image_parts, 1, length(local.api_image_parts)))
    : local.api_image_ref
  )
  # An explicit tag is guaranteed by the api_image validation block.
  api_image_tag  = regex(":([^:/]+)$", local.api_repository_ref)[0]
  api_repository = trimsuffix(local.api_repository_ref, ":${local.api_image_tag}")

  # acrUseManagedIdentityCreds is an Azure Container Registry feature; GHCR and Docker Hub reject it.
  api_registry_is_acr = endswith(local.api_registry_host, ".azurecr.io")
}

locals {
  frontend_possible_outbound_ips = distinct([
    for ip in split(",", var.frontend_possible_outbound_ip_addresses) : trimspace(ip)
  ])

  allow_frontend_outbound_ips = [
    for index, ip in local.frontend_possible_outbound_ips : {
      action                    = "Allow"
      name                      = "AFInbound${replace(ip, ".", "")}"
      priority                  = 200 + index
      ip_address                = ip != "" ? "${ip}/32" : null
      virtual_network_subnet_id = ip == "" ? var.app_service_subnet_id : null
      service_tag               = ip == "" ? "AppService" : null
      headers                   = null
    }
  ]

  allow_frontdoor = var.enable_frontdoor ? [
    {
      action      = "Allow"
      name        = "Allow traffic from Front Door"
      priority    = 100
      service_tag = "AzureFrontDoor.Backend"
      ip_address  = null

      virtual_network_subnet_id = null
      headers = {
        x_azure_fdid      = [var.frontend_frontdoor_resource_guid]
        x_fd_health_probe = []
        x_forwarded_for   = []
        x_forwarded_host  = []
      }
    }
  ] : []

  # "Deny all other traffic" — lowest-priority catch-all once Front Door is enabled.
  deny_all = var.enable_frontdoor ? [
    {
      action                    = "Deny"
      name                      = "DenyAll"
      priority                  = 1000
      ip_address                = "0.0.0.0/0"
      service_tag               = null
      virtual_network_subnet_id = null
      headers                   = null
    }
  ] : []

  backend_ip_restrictions = concat(
    local.allow_frontend_outbound_ips,
    local.allow_frontdoor,
    local.deny_all
  )
}
