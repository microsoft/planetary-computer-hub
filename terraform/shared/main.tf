provider "azurerm" {
  features {}
}

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.74.0"
    }

  }
  backend "azurerm" {
    resource_group_name  = "pc-manual-resources"
    storage_account_name = "pctfstate"
    container_name       = "pcc"
    key                  = "shared.tfstate"
  }

}

locals {
  stack_id = "pcc"
  region   = "West Europe"
  location = lower(replace(local.region, " ", ""))
  prefix   = "${local.stack_id}-${local.location}"
}


# Shared volumes for datasets

resource "azurerm_resource_group" "shared" {
  name     = "${local.prefix}-shared-rg"
  location = "West Europe"
  tags = {
    "ringValue" = "r1"
  }
}

resource "azurerm_storage_account" "pc-compute" {
  name                     = "${replace(local.prefix, "-", "")}storage"
  resource_group_name      = azurerm_resource_group.shared.name
  location                 = azurerm_resource_group.shared.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# resource "azurerm_storage_share" "pc-compute" {
#   name                 = "driven-data"
#   storage_account_name = azurerm_storage_account.pc-compute.name
#   quota                = 100
# }
