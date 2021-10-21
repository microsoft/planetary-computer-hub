resource "azurerm_virtual_network" "pc_compute" {
  name                = "${local.maybe_staging_prefix}-network"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name
  address_space       = ["10.0.0.0/8"]
  tags                = {}
}

resource "azurerm_network_security_group" "pc_compute" {
  name                = "${local.maybe_staging_prefix}-nsg"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name
}


resource "azurerm_subnet" "node_subnet" {
  name                 = "${local.maybe_staging_prefix}-node-subnet"
  virtual_network_name = azurerm_virtual_network.pc_compute.name
  resource_group_name  = azurerm_resource_group.pc_compute.name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_subnet_network_security_group_association" "pc_compute" {
  subnet_id                 = azurerm_subnet.node_subnet.id
  network_security_group_id = azurerm_network_security_group.pc_compute.id
}
