terraform {
  required_version = ">= 1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0.0, < 6.0.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.8.0, < 3.0.0"
    }
  }
}
