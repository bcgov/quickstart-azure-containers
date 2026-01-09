locals {
  frontend_possible_outbound_ips = [
    for ip in split(",", var.frontend_possible_outbound_ip_addresses) : trimspace(ip)
  ]

  allow_frontend_outbound_ips = {
    for ip in local.frontend_possible_outbound_ips :
    "allow_frontend_${replace(ip, ".", "_")}" => {
      action     = "Allow"
      name       = "AFInbound${replace(ip, ".", "")}"
      priority   = 100
      ip_address = ip != "" ? "${ip}/32" : null

      virtual_network_subnet_id = ip == "" ? var.app_service_subnet_id : null
      service_tag               = ip == "" ? "AppService" : null
    }
  }

  allow_frontdoor = var.enable_frontdoor ? {
    allow_frontdoor = {
      action      = "Allow"
      name        = "Allow traffic from Front Door"
      priority    = 100
      service_tag = "AzureFrontDoor.Backend"

      headers = {
        default = {
          x_azure_fdid      = [var.frontend_frontdoor_resource_guid]
          x_fd_health_probe = []
          x_forwarded_for   = []
          x_forwarded_host  = []
        }
      }
    }
  } : {}

  deny_all = var.enable_frontdoor ? {
    deny_all = {
      action      = "Deny"
      name        = "DenyAll"
      priority    = 500
      ip_address  = "0.0.0.0/0"
      description = "Deny all other traffic"
    }
  } : {}

  backend_ip_restrictions = merge(
    local.allow_frontend_outbound_ips,
    local.allow_frontdoor,
    local.deny_all
  )
}
