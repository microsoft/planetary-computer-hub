resource "azurerm_virtual_network" "pc_compute" {
  name                = "${local.prefix}-network"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name
  address_space       = ["10.0.0.0/8"]
  tags                = {}
}

resource "azurerm_subnet" "node_subnet" {
  name                 = "${local.prefix}-node-subnet"
  virtual_network_name = azurerm_virtual_network.pc_compute.name
  resource_group_name  = azurerm_resource_group.pc_compute.name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_network_security_group" "pc_compute" {
  name                = "${local.prefix}-security-group"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name

  security_rule {
    name                       = "hub-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "pc_compute" {
  subnet_id                 = azurerm_subnet.node_subnet.id
  network_security_group_id = azurerm_network_security_group.pc_compute.id
}
