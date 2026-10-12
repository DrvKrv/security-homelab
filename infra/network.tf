# network.tf - the resource group, the private network, and the subnet.
#
# Read this top to bottom: it's the skeleton everything else attaches to.
# Each `resource` block is one thing in Azure. The first string is its type,
# the second is a name YOU choose to refer to it elsewhere in the code
# (e.g. azurerm_subnet.lab.id below).

resource "azurerm_resource_group" "lab" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# The virtual network: your own slice of private address space in Azure.
resource "azurerm_virtual_network" "lab" {
  name                = var.vnet_name
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# The subnet the VMs live on. Everything inside a VNet can talk to everything
# else in it by default (that's how the Wazuh agents reach the manager on
# 1514/1515 without any extra rule).
resource "azurerm_subnet" "lab" {
  name                 = "lab-subnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = [var.lab_subnet_cidr]
}

# A fixed private IP for each VM, so the addresses in your notes stay true.
# (Azure hands these out from the subnet; we just pin the last octet.)
locals {
  ips = {
    wazuh     = cidrhost(var.lab_subnet_cidr, 10) # 10.0.1.10
    win_srv   = cidrhost(var.lab_subnet_cidr, 20) # 10.0.1.20
    linux_srv = cidrhost(var.lab_subnet_cidr, 30) # 10.0.1.30
    web_srv   = cidrhost(var.lab_subnet_cidr, 40) # 10.0.1.40
    dc01      = cidrhost(var.lab_subnet_cidr, 50) # 10.0.1.50
  }
}
