# zones.tf - Unit 8: split the network into zones. THE WORKED EXAMPLE FOR ZONES.
#
# So far every VM sits in one subnet, and Azure lets everything inside a VNet
# talk to everything else. That's "flat": if web-srv (the machine most exposed
# to attack) is taken over, nothing stops it reaching dc01, the keys to the
# whole company.
#
# Segmentation fixes that. With enable_zones = true:
#   DMZ zone       10.0.2.0/24   web-srv (10.0.2.40): the "front door"
#   internal zone  10.0.1.0/24   wazuh, win-srv, linux-srv, dc01
#
# The DMZ's firewall (below) allows only what the design needs:
#   in:  web pages (80) and the training app (3000) from the internal zone,
#        and SSH (22) from win-srv, your jump host
#   out: the Wazuh agent's two ports to wazuh, and nothing else internal
#   everything else between the zones: denied
#
# The internal zone gets its own firewall too (defence in depth: if someone
# loosens the DMZ rules, the internal side still says no). That one you write:
# zones-internal.tf.todo, exercise 06. The answer key is answers/zones-internal.tf.
#
# Things to know about NSGs before you change these rules:
#   - Lower priority number = checked first. The first rule that matches wins.
#   - NSGs are stateful: if a connection is allowed in, its replies are allowed
#     out automatically. You only write rules for who may START a connection.
#   - Azure's built-in rules (priority 65000+) allow all traffic inside the VNet.
#     That's why the explicit Deny rules at 4000 are needed: they come first.
#   - A subnet NSG and a NIC NSG both apply. Traffic has to pass both.

resource "azurerm_subnet" "dmz" {
  count                = var.enable_zones ? 1 : 0
  name                 = "dmz-subnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = [var.dmz_subnet_cidr]
}

resource "azurerm_network_security_group" "dmz" {
  count               = var.enable_zones ? 1 : 0
  name                = "dmz-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags

  # ---- inbound: who may start a connection INTO the DMZ ----
  security_rule {
    name                       = "Allow-web-from-internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "3000"]
    source_address_prefix      = var.lab_subnet_cidr
    destination_address_prefix = var.dmz_subnet_cidr
  }

  security_rule {
    name                       = "Allow-ssh-from-jump-host"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.ips.win_srv
    destination_address_prefix = var.dmz_subnet_cidr
  }

  security_rule {
    name                       = "Deny-other-vnet-in"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # ---- outbound: where the DMZ may start a connection TO ----
  security_rule {
    name                       = "Allow-wazuh-agent"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1514-1515"
    source_address_prefix      = var.dmz_subnet_cidr
    destination_address_prefix = local.ips.wazuh
  }

  security_rule {
    name                       = "Deny-dmz-to-internal"
    priority                   = 4000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.dmz_subnet_cidr
    destination_address_prefix = var.lab_subnet_cidr
  }
  # Outbound to the internet stays allowed by Azure's default rule, so web-srv
  # can still download updates and container images.
}

resource "azurerm_subnet_network_security_group_association" "dmz" {
  count                     = var.enable_zones ? 1 : 0
  subnet_id                 = azurerm_subnet.dmz[0].id
  network_security_group_id = azurerm_network_security_group.dmz[0].id
}
