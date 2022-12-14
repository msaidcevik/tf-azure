terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.35.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_resource_group" "rg-storage" {
  name     = "storage-rg"
  location = "North Europe"
}

resource "azurerm_storage_account" "sa" {
  name                     = "said13"
  resource_group_name      = azurerm_resource_group.rg-storage.name
  location                 = azurerm_resource_group.rg-storage.location
  account_tier              = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                  = "first1container"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "blob" {
  name                   = "said13"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
}