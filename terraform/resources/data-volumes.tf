# # Shared volumes for datasets

resource "azurerm_storage_account" "pc-compute" {
  name                     = "${replace(local.maybe_staging_prefix, "-", "")}storage"
  resource_group_name      = azurerm_resource_group.pc_compute.name
  location                 = azurerm_resource_group.pc_compute.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "pc-compute" {
  name                 = "driven-data"
  storage_account_name = azurerm_storage_account.pc-compute.name
  quota                = 100
}

resource "kubernetes_secret" "pc-compute-fileshare" {
  metadata {
    name      = "driven-data-file-share"
    namespace = var.environment
  }

  data = {
    azurestorageaccountname = azurerm_storage_account.pc-compute.name
    azurestorageaccountkey  = azurerm_storage_account.pc-compute.primary_access_key
  }
}
