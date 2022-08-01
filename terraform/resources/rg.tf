resource "azurerm_resource_group" "pc_compute" {
  name     = "${local.maybe_versioned_prefix}-rg"
  location = var.region
  tags = {
    environment = var.environment
    component   = "hub"
    ringValue   = "r1"
  }
}
