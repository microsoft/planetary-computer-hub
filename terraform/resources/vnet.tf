resource "azurerm_virtual_network" "pc_compute" {
  name                = "${local.maybe_staging_prefix}-network"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name
  address_space       = ["10.0.0.0/8"]
  tags                = {}
}

resource "azurerm_subnet" "node_subnet" {
  name                 = "${local.maybe_staging_prefix}-node-subnet"
  virtual_network_name = azurerm_virtual_network.pc_compute.name
  resource_group_name  = azurerm_resource_group.pc_compute.name
  address_prefixes     = ["10.1.0.0/16"]
}