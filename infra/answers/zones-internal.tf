# ANSWER KEY for exercise 06 (zones-internal.tf). Don't peek until you've tried.
#
# Terraform only reads .tf files in the folder it runs in, so this file in
# answers/ is ignored until you copy it up: cp answers/zones-internal.tf .

resource "azurerm_network_security_group" "internal" {
  count               = var.enable_zones ? 1 : 0
  name                = "internal-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags

  # The one thing the DMZ may start inside: its Wazuh agent talking to the manager.
  security_rule {
    name                       = "Allow-dmz-wazuh-agent"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1514-1515"
    source_address_prefix      = var.dmz_subnet_cidr
    destination_address_prefix = local.ips.wazuh
  }

  # Everything else the DMZ starts is refused. 4000 beats Azure's built-in
  # AllowVnetInBound (65000). Replies to connections the internal side starts
  # (win-srv browsing web-srv) still work, because NSGs are stateful.
  security_rule {
    name                       = "Deny-from-dmz"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.dmz_subnet_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "internal" {
  count                     = var.enable_zones ? 1 : 0
  subnet_id                 = azurerm_subnet.lab.id
  network_security_group_id = azurerm_network_security_group.internal[0].id
}
