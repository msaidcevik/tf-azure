### Requirements
- Let the `address_space` `["10.122.0.0/16"]` and subnet `["10.122.1.0/24"]` with location `East US`. 
- Allow `Tcp` protcol with Inbound rule. And let `public_ip` be dynamic 
- Create linux virtual machine
    - `Standard_B1s`, admin_user = adminuser, and `Ubuntu 18.04-LTS` 

## Part-1 Create network and public_ip
- Firstly create a file named `main.tf` for the configuration code and copy and paste the following content.  

```go
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
```

## Virtual Network
- Azure virtual network enables Azure resources to securely communicate with each other, the internet, and on-premises networks. You can accomplish with a virtual network include - communication of Azure resources with the internet, communication between Azure resources, communication with on-premises resources, filtering network traffic, routing network traffic, and integration with Azure services.

- Add to the `main.tf` file and make changes.
```go
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
```

## Subnet
- Subnets represent network segments within the IP space defined by the virtual network.

```go 
resource "azurerm_subnet" "docker-subnet" {
  name                 = "docker-subnet"
  resource_group_name  = azurerm_resource_group.docker-rg.name
  virtual_network_name = azurerm_virtual_network.docker-vn.name
  address_prefixes     = ["10.122.1.0/24"]
}
```

## Network Security Group
- Manages a network security group that contains a list of network security rules. Network security groups enable inbound or outbound traffic to be enabled or denied.

```go
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
```

## azurerm_subnet_network_security_group_association
- Associates a Network Security Group with a Subnet within a Virtual Network.

```go 
resource "azurerm_subnet_network_security_group_association" "docker-sga" {
  subnet_id                 = azurerm_subnet.docker-subnet.id
  network_security_group_id = azurerm_network_security_group.docker-sg.id
}
```

- Add to the `main.tf` public ip configuration.

```go
resource "azurerm_public_ip" "docker-ip" {
  name                = "docker-ip"
  resource_group_name = azurerm_resource_group.docker-rg.name
  location            = azurerm_resource_group.docker-rg.location
  allocation_method   = "Dynamic"

  tags = {
    "environment" = "dev"
  }
}
```
- Write to the terminal and apply `main.tf`

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

- Now go to the terminal and try to see `public_ip`. Firstly list created resources 

```bash
terraform state list
```
- Copy `azurerm_public_ip.docker-ip` and look at

```bash
terraform state show azurerm_public_ip.docker-ip
```
- But we still can't see public_ip and now add `network_interface`

## Network Interface
- A network interface enables an Azure Virtual Machine to communicate with internet, Azure, and on-premises resources. A virtual machine created with the Azure portal, has one network interface with default settings.

```go
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
```
- Go to the terminal and write code

```bash
terraform apply -auto-approve
```
- Try to see `public_ip` and ``private_ip`. Firstly list created resources 

```bash
terraform state list
```
- Copy `azurerm_network_interface.docker-nic` and

```bash
terraform state show azurerm_network_interface.docker-nic
```
- You can see `private_ip`, but don't still see `public_ip`.

- Now create linux virtual machine 

```go 
resource "azurerm_linux_virtual_machine" "docker-vm" {
  name                  = "docker-vm"
  resource_group_name   = azurerm_resource_group.docker-rg.name
  location              = azurerm_resource_group.docker-rg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.docker-nic.id]

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
```

- Create key for `SSH` connection. Go to the terminal

```bash
ssh-keygen -t rsa 
```
- Configure `main.tf` and add `admin_ssh_key`

```go
resource "azurerm_linux_virtual_machine" "docker-vm" {
  name                  = "docker-vm"
  resource_group_name   = azurerm_resource_group.docker-rg.name
  location              = azurerm_resource_group.docker-rg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.docker-nic.id]

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
```

- Create script file for Docker install.

```bash
touch docker_install.sh
```

- Copy and paste the following content `docker_install.sh`.

```sh
#!/bin/bash
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo systemctl status docker
sudo groupadd docker
sudo usermod -aG docker adminuser  # username = adminuser
newgrp docker
sudo systemctl enable docker 
```

- Add `docker_install.sh` as filebase64 `main.tf`.

```go
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
```












