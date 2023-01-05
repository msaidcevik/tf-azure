terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.37.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "docker-rg" {
  name     = "docker-resources"
  location = "East US"
  tags = {
    "environment" = "dev"
  }
}

resource "azurerm_virtual_network" "docker-vn" {
  name                = "docker-network"
  resource_group_name = azurerm_resource_group.docker-rg.name
  location            = azurerm_resource_group.docker-rg.location
  address_space       = ["10.122.0.0/16"]
  tags = {
    "environment" = "dev"
  }
}

resource "azurerm_subnet" "docker-subnet" {
  name                 = "docker-subnet"
  resource_group_name  = azurerm_resource_group.docker-rg.name
  virtual_network_name = azurerm_virtual_network.docker-vn.name
  address_prefixes     = ["10.122.1.0/24"]
}

resource "azurerm_network_security_group" "docker-sg" {
  name                = "docker-sg"
  location            = azurerm_resource_group.docker-rg.location
  resource_group_name = azurerm_resource_group.docker-rg.name

  tags = {
    "environment" = "dev"
  }
}

resource "azurerm_network_security_rule" "docker-dev-rule" {
  name                        = "docker-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.docker-rg.name
  network_security_group_name = azurerm_network_security_group.docker-sg.name
}

resource "azurerm_subnet_network_security_group_association" "docker-sga" {
  subnet_id                 = azurerm_subnet.docker-subnet.id
  network_security_group_id = azurerm_network_security_group.docker-sg.id
}

resource "azurerm_public_ip" "docker-ip" {
  name                = "docker-ip"
  resource_group_name = azurerm_resource_group.docker-rg.name
  location            = azurerm_resource_group.docker-rg.location
  allocation_method   = "Dynamic"

  tags = {
    "environment" = "dev"
  }
}

resource "azurerm_network_interface" "docker-nic" {
  name                = "docker-nic"
  location            = azurerm_resource_group.docker-rg.location
  resource_group_name = azurerm_resource_group.docker-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.docker-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.docker-ip.id
  }

  tags = {
    "environment" = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "docker-vm" {
  name                  = "docker-vm"
  resource_group_name   = azurerm_resource_group.docker-rg.name
  location              = azurerm_resource_group.docker-rg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.docker-nic.id]

  custom_data = filebase64("./docker_install.sh")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("/home/oem/ssh/mtcazurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    "environment" = "dev"
  }
}

data "azurerm_public_ip" "docker_ip_data" {
  name = azurerm_public_ip.docker-ip.name
  resource_group_name = azurerm_resource_group.docker-rg.name
}

output "public_ip_address" {
  value = "${azurerm_linux_virtual_machine.docker-vm.name}: ${data.azurerm_public_ip.docker_ip_data.ip_address}"
}