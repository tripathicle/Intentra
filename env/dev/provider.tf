terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.4.0"
    }
  }

  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate-hubandspokewl"
  #   storage_account_name = "sttfstatehubandspoke"
  #   container_name       = "tfstate"
  #   key                  = "workload/dev.tfstate"
  #   use_azuread_auth     = true
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = "c429b37e-b7b4-400e-a794-2d7d312aa3b4"
}