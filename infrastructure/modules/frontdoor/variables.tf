variable "app_name" {
  description = "Name of the application"
  type        = string
  nullable    = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  nullable    = false
}
variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  nullable    = false
}
