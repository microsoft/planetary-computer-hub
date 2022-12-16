resource "azurerm_virtual_network" "pc_compute" {
  name                = "${var.maybe_versioned_prefix}-network"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name
  address_space       = ["10.0.0.0/8"]
  tags                = {}
}

resource "azurerm_subnet" "node_subnet" {
  name                 = "${var.maybe_versioned_prefix}-node-subnet"
  virtual_network_name = azurerm_virtual_network.pc_compute.name
  resource_group_name  = azurerm_resource_group.pc_compute.name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "ag_subnet" {
  name                 = "${var.maybe_versioned_prefix}-ag-subnet"
  virtual_network_name = azurerm_virtual_network.pc_compute.name
  resource_group_name  = azurerm_resource_group.pc_compute.name
  address_prefixes     = ["10.2.0.0/16"]
  service_endpoints    = ["Microsoft.KeyVault"]
}

resource "azurerm_network_security_group" "pc_compute" {
  name                = "${var.maybe_versioned_prefix}-security-group"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name
}

resource "azurerm_public_ip" "pc_compute" {
  name                = var.pip_name
  resource_group_name = azurerm_resource_group.pc_compute.name
  location            = azurerm_resource_group.pc_compute.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.dns_label
}

data "azurerm_application_gateway" "pc_compute" {
  name                = var.appgw_name
  resource_group_name = azurerm_resource_group.pc_compute.name
}
