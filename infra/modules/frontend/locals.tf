locals {
  frontend_ip_restrictions = var.enable_frontdoor ? tomap({
    allow_frontdoor = {
      action                    = "Allow"
      name                      = "Allow traffic from Front Door"
      priority                  = 100
      service_tag               = "AzureFrontDoor.Backend"
      ip_address                = null
      virtual_network_subnet_id = null
      description               = null
      headers = {
        default = {
          x_azure_fdid      = [var.frontend_frontdoor_resource_guid]
          x_fd_health_probe = []
          x_forwarded_for   = []
          x_forwarded_host  = []
        }
      }
    }
    }) : tomap({
    allow_all = {
      action                    = "Allow"
      name                      = "AllowAll"
      priority                  = 100
      ip_address                = "0.0.0.0/0"
      service_tag               = null
      virtual_network_subnet_id = null
      description               = null
      headers                   = tomap({})
    }
  })
}
