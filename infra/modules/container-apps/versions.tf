terraform {
  required_version = ">= 1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.57.0, < 5.0.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.7.0, < 3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.4, < 4.0.0"
    }
  }
}
