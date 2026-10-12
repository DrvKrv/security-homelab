# web-srv.tf - Stage 2's VM, defined in code. THIS IS YOUR WORKED EXAMPLE.
#
# Read it closely: dc01 is the one you'll write yourself, using this as the model
# (see exercises/03-write-dc01.md).
#
# The `count = var.enable_web_srv ? 1 : 0` trick means:
#   enable_web_srv = false  ->  count 0  ->  this VM is NOT created
#   enable_web_srv = true   ->  count 1  ->  it is
# So you add the machine by flipping one variable and running `apply`, and remove
# it (to stop charges) by flipping it back. Because of count, each resource is
# referred to with [0], e.g. azurerm_network_interface.web_srv[0].id .

# No public IP block here at all - web-srv is reachable only from inside the lab.
resource "azurerm_network_interface" "web_srv" {
  count               = var.enable_web_srv ? 1 : 0
  name                = "web-srv-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.ips.web_srv
  }
}

# Empty NSG = default deny from the internet, allow inside the VNet. Lab-only.
resource "azurerm_network_security_group" "web_srv" {
  count               = var.enable_web_srv ? 1 : 0
  name                = "web-srv-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags
}

resource "azurerm_network_interface_security_group_association" "web_srv" {
  count                     = var.enable_web_srv ? 1 : 0
  network_interface_id      = azurerm_network_interface.web_srv[0].id
  network_security_group_id = azurerm_network_security_group.web_srv[0].id
}

# cloud-init: on first boot the VM clones the repo and runs the stage installer
# by itself, so the stage scripts from lab/stages/2-web-srv/ get reused, not
# rewritten. (runcmd runs as root.)
locals {
  web_srv_cloud_init = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - git
    runcmd:
      - git clone https://github.com/DrvKrv/security-homelab.git /opt/security-homelab
      - bash /opt/security-homelab/lab/stages/2-web-srv/install.sh
  CLOUDINIT
  )
}

resource "azurerm_linux_virtual_machine" "web_srv" {
  count                 = var.enable_web_srv ? 1 : 0
  name                  = "web-srv"
  resource_group_name   = azurerm_resource_group.lab.name
  location              = azurerm_resource_group.lab.location
  size                  = var.vm_size_linux
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.web_srv[0].id]
  custom_data           = local.web_srv_cloud_init
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
