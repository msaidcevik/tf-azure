terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.36.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "module_vnetwork" {
  name = "${var.environment}-module-network"
  location = "North Europe"
  tags = {
    "Name" = "${var.environment}-resource-network"
  }
}

resource "azurerm_virtual_network" "network" {
  name = "virtual_network"
  address_space = [ "${var.address_space}" ]
  location = azurerm_resource_group.module_vnetwork.location
  resource_group_name = azurerm_resource_group.module_vnetwork.name
  tags = {
    "Name" = "tf-network-${var.environment}"
  }
}

resource "azurerm_subnet" "public_subnet" {
  name = "public-subnet-${var.environment}"
  resource_group_name = azurerm_resource_group.module_vnetwork.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes = [ "${var.public_address_prefixes}"]
}

resource "azurerm_subnet" "private_subnet" {
  name = "private-subnet-${var.environment}"
  resource_group_name = azurerm_resource_group.module_vnetwork.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes = [ "${var.private_address_prefixes}" ]
}

