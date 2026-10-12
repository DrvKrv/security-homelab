# answers/dc01.tf - one correct version of the dc01 file.
#
# SPOILER. Try exercises/03-write-dc01.md yourself first. This folder is NOT read
# by Terraform (it only reads .tf files in the infra/ root), so this is just a
# reference. To actually use it, you'd copy it up to infra/dc01.tf - but you'll
# learn far more by writing your own and only checking against this.

resource "azurerm_network_interface" "dc01" {
  count               = var.enable_dc01 ? 1 : 0
  name                = "dc01-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.ips.dc01
  }
}

resource "azurerm_network_security_group" "dc01" {
  count               = var.enable_dc01 ? 1 : 0
  name                = "dc01-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags
}

resource "azurerm_network_interface_security_group_association" "dc01" {
  count                     = var.enable_dc01 ? 1 : 0
  network_interface_id      = azurerm_network_interface.dc01[0].id
  network_security_group_id = azurerm_network_security_group.dc01[0].id
}

resource "random_password" "dc01" {
  count            = var.enable_dc01 ? 1 : 0
  length           = 24
  special          = true
  override_special = "!#$%*-_=+"
}

resource "azurerm_windows_virtual_machine" "dc01" {
  count                 = var.enable_dc01 ? 1 : 0
  name                  = "dc01"
  resource_group_name   = azurerm_resource_group.lab.name
  location              = azurerm_resource_group.lab.location
  size                  = var.vm_size_windows
  admin_username        = var.admin_username
  admin_password        = random_password.dc01[0].result
  network_interface_ids = [azurerm_network_interface.dc01[0].id]
  tags                  = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-azure-edition"
    version   = "latest"
  }
}

# And in outputs.tf you'd add:
#   output "dc01_private_ip" {
#     value = var.enable_dc01 ? azurerm_windows_virtual_machine.dc01[0].private_ip_address : "dc01 disabled"
#   }
