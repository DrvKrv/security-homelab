# firewall.tf - Network Security Groups (NSGs), Azure's firewall in front of each VM.
#
# This is the file a security reviewer reads first, because a single wrong line
# here is how real breaches start (e.g. RDP open to the whole internet). Keep it
# tight, and run a scanner over it (see exercises/04-find-the-misconfig.md).
#
# The design, matching your lab notes:
#   - win-srv:   allow RDP (3389) FROM YOUR HOME IP ONLY. Nothing else inbound.
#   - wazuh:     no custom inbound rules. The default "allow inside the VNet,
#                deny everything from the internet" is exactly what we want.
#   - linux-srv: same as wazuh - no public exposure at all.
#   - web-srv / dc01: same again (defined in their own files) - lab-only.

# --- win-srv: the only machine reachable from the internet, and only by you ---
resource "azurerm_network_security_group" "win_srv" {
  name                = "win-srv-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-RDP-from-my-ip"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.admin_source_ip # your home IP, NOT the internet
    destination_address_prefix = "*"
  }
  # Azure already adds, at lower priority: AllowVnetInBound, then DenyAllInBound.
  # So everything from the internet except your RDP is blocked by default.
}

resource "azurerm_network_interface_security_group_association" "win_srv" {
  network_interface_id      = azurerm_network_interface.win_srv.id
  network_security_group_id = azurerm_network_security_group.win_srv.id
}

# --- wazuh and linux-srv: no custom inbound rules, relying on the safe defaults.
# We still create an (empty) NSG for each so the "default deny from internet" is
# explicit and attached, rather than left to chance.
resource "azurerm_network_security_group" "wazuh" {
  name                = "wazuh-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags
}

resource "azurerm_network_interface_security_group_association" "wazuh" {
  network_interface_id      = azurerm_network_interface.wazuh.id
  network_security_group_id = azurerm_network_security_group.wazuh.id
}

resource "azurerm_network_security_group" "linux_srv" {
  name                = "linux-srv-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags
}

resource "azurerm_network_interface_security_group_association" "linux_srv" {
  network_interface_id      = azurerm_network_interface.linux_srv.id
  network_security_group_id = azurerm_network_security_group.linux_srv.id
}
