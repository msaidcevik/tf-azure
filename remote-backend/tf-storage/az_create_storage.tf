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

resource "random_string" "resource_code" {
  length  = 5
  special = true
  upper   = false
}

resource "azurerm_resource_group" "rg-storage" {
  name     = "tfstate"
  location = "North Europe"
  tags = {
    "Name" = "tfstate-rg"
  }
}

resource "azurerm_storage_account" "sa" {
  name                     = "said13"
  resource_group_name      = azurerm_resource_group.rg-storage.name
  location                 = azurerm_resource_group.rg-storage.location
  account_tier              = "Standard"
  account_replication_type = "LRS"
  tags = {
    "Name" = "tfstate-storage-account"
  }
}

resource "azurerm_storage_encryption_scope" "encrp" {
  name = "microsoftmanaged"
  storage_account_id = azurerm_storage_account.sa.id
  source             = "Microsoft.Storage"
}

resource "azurerm_storage_container" "container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "blob" {
  name                   = "said13"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
}