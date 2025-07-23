# Calculate subnet CIDRs based on VNet address space
locals {
  # Split the address space
  vnet_ip_base                   = split("/", var.vnet_address_space)[0]
  octets                         = split(".", local.vnet_ip_base)
  base_ip                        = "${local.octets[0]}.${local.octets[1]}.${local.octets[2]}"
  app_service_subnet_cidr        = "${local.base_ip}.0/27"
  web_subnet_cidr                = "${local.base_ip}.32/27"
  private_endpoints_subnet_cidr  = "${local.base_ip}.64/28"
  container_instance_subnet_cidr = "${local.base_ip}.80/28"
}
