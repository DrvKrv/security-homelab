# core.tf - the three VMs you already built by hand: wazuh, win-srv, linux-srv.
#
# These describe what your lab already looks like. You won't `apply` these to
# create new machines - the machines exist. Instead this is what you IMPORT your
# real VMs into, so Terraform manages them from here on. See
# exercises/05-import-existing-vms.md. Until you import them, leave these as-is
# and only turn on the new stages (web-srv, dc01), which are safe to create fresh.
#
# NOTE: `source_image_reference` and `size` must match your real VMs or an import
# will show drift. Adjust the image publisher/offer/sku to what you actually
# deployed if `terraform plan` reports a difference after import.

# ---------------- wazuh (Ubuntu 24.04, the SIEM) ----------------
resource "azurerm_network_interface" "wazuh" {
  name                = "wazuh-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.ips.wazuh
  }
}

resource "azurerm_linux_virtual_machine" "wazuh" {
  name                  = "wazuh"
  resource_group_name   = azurerm_resource_group.lab.name
  location              = azurerm_resource_group.lab.location
  size                  = var.vm_size_wazuh
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.wazuh.id]
  tags                  = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# ---------------- linux-srv (Ubuntu 24.04, log source) ----------------
resource "azurerm_network_interface" "linux_srv" {
  name                = "linux-srv-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.ips.linux_srv
  }
}

resource "azurerm_linux_virtual_machine" "linux_srv" {
  name                  = "linux-srv"
  resource_group_name   = azurerm_resource_group.lab.name
  location              = azurerm_resource_group.lab.location
  size                  = var.vm_size_linux
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.linux_srv.id]
  tags                  = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# ---------------- win-srv (Windows Server 2025, jump host) ----------------
# The only VM with a public IP, and only your home IP can RDP to it (firewall.tf).
resource "azurerm_public_ip" "win_srv" {
  name                = "win-srv-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "win_srv" {
  name                = "win-srv-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.ips.win_srv
    public_ip_address_id          = azurerm_public_ip.win_srv.id
  }
}

# The Windows admin password is generated here and kept only in Terraform state
# (which is git-ignored). Read it after apply with:
#   terraform output -raw win_srv_admin_password
resource "random_password" "win_srv" {
  length           = 24
  special          = true
  override_special = "!#$%*-_=+"
}

resource "azurerm_windows_virtual_machine" "win_srv" {
  name                  = "win-srv"
  resource_group_name   = azurerm_resource_group.lab.name
  location              = azurerm_resource_group.lab.location
  size                  = var.vm_size_windows
  admin_username        = var.admin_username
  admin_password        = random_password.win_srv.result
  network_interface_ids = [azurerm_network_interface.win_srv.id]
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
