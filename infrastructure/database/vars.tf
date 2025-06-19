variable "resource_group_name" {
    description = "Name of the resource group where resources will be created"
    type        = string
}

variable "location" {
    description = "Azure region where resources will be located"
    type        = string
    default     = "canadacentral"
}

variable "vnet_name" {
    description = "Name of the virtual network"
    type        = string
}

variable "vnet_address_space" {
    description = "Address space for the virtual network"
    type        = list(string)
}

variable "subnet_names" {
    description = "Names of subnets to create in the virtual network"
    type        = list(string)
    default     = ["default"]
}

variable "subnet_prefixes" {
    description = "CIDR prefixes for subnets"
    type        = list(string)
    default     = ["10.0.1.0/24"]
}

variable "tags" {
    description = "Tags to apply to resources"
    type        = map(string)
    default     = {}
}