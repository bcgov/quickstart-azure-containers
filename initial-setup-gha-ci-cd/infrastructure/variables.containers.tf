variable "compute_types" {
  description = "The types of compute to use. Allowed values are 'azure_container_app' and 'azure_container_instance'."
  type        = set(string)
  default     = ["azure_container_app"]

  validation {
    condition     = alltrue([for compute_type in var.compute_types : contains(["azure_container_app", "azure_container_instance"], compute_type)])
    error_message = "compute_types must be a combination of 'azure_container_app' and 'azure_container_instance'"
  }
}

variable "container_instance_count" {
  description = "The number of container instances to create"
  type        = number
  default     = 2 # Note: AVM module defaults to 2 instances
}
