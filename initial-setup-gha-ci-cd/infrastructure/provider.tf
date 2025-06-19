terraform {
  required_version = ">= 1.9.0"

  # backend "azurerm" {
  #   resource_group_name  = "tfstate"
  #   storage_account_name = "tfstate"
  #   container_name       = "tfstate"
  #   key                  = "terraform.tfstate"
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }

    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "azurerm" {
  use_oidc = true
  features {
    # NOTE: This is required because we have the Azure Monitor Baseline Alerts policies in place,
    # which auto-create metric alerts for specific resources types within the Resource Group where the resource is created.
    # The AMBA metic alerts prevent the deletion of the Resource Group, as they are not created by this module.
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  # subscription_id is now required with AzureRM provider 4.0. Use either of the following methods:
  subscription_id = "ffc5e617-7f2d-4ddb-8b57-33fc43989a8c"
  # export ARM_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
}

provider "azapi" {
}
