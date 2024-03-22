resource "azurerm_resource_group" "pc_compute" {
  name     = "${var.maybe_versioned_prefix}-rg"
  location = var.region
  tags = {
    environment = var.environment
    component   = "hub"
    ringValue   = "r1"

    deployment_source = "https://github.com/microsoft/planetary-computer-hub"
  }
}
