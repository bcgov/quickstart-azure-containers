locals {
  # avm-res-web-site composes linuxFxVersion as DOCKER|<registry-host>/<repository>:<tag>,
  # so a full image reference has to be split back into its three parts.
  frontend_image_ref   = trimprefix(trimprefix(var.frontend_image, "https://"), "http://")
  frontend_image_parts = split("/", local.frontend_image_ref)
  frontend_image_has_registry = length(local.frontend_image_parts) > 1 && (
    strcontains(local.frontend_image_parts[0], ".") || strcontains(local.frontend_image_parts[0], ":")
  )
  frontend_registry_host = (
    local.frontend_image_has_registry
    ? local.frontend_image_parts[0]
    : trimprefix(trimprefix(var.container_registry_url, "https://"), "http://")
  )
  frontend_repository_ref = (
    local.frontend_image_has_registry
    ? join("/", slice(local.frontend_image_parts, 1, length(local.frontend_image_parts)))
    : local.frontend_image_ref
  )
  # An explicit tag is guaranteed by the frontend_image validation block.
  frontend_image_tag  = regex(":([^:/]+)$", local.frontend_repository_ref)[0]
  frontend_repository = trimsuffix(local.frontend_repository_ref, ":${local.frontend_image_tag}")

  # acrUseManagedIdentityCreds is an Azure Container Registry feature; GHCR and Docker Hub reject it.
  frontend_registry_is_acr = endswith(local.frontend_registry_host, ".azurecr.io")
}

locals {
  frontend_ip_restrictions = var.enable_frontdoor ? [
    {
      action                    = "Allow"
      name                      = "Allow traffic from Front Door"
      priority                  = 100
      service_tag               = "AzureFrontDoor.Backend"
      ip_address                = null
      virtual_network_subnet_id = null
      headers = {
        x_azure_fdid      = [var.frontend_frontdoor_resource_guid]
        x_fd_health_probe = []
        x_forwarded_for   = []
        x_forwarded_host  = []
      }
    }
    ] : [
    {
      action                    = "Allow"
      name                      = "AllowAll"
      priority                  = 200
      ip_address                = "0.0.0.0/0"
      service_tag               = null
      virtual_network_subnet_id = null
      headers                   = null
    }
  ]
}
