# This is prod-only.
# I had to change the terraform resource references to constants
# to get prod to deploy correctly.
resource "azurerm_container_registry" "container_registry" {
  name                = "pcccr"
  resource_group_name = "pcc-westeurope-rg"
  location            = "West Europe"
  sku                 = "premium"
  admin_enabled       = true
}