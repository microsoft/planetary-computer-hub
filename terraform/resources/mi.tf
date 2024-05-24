resource "azurerm_user_assigned_identity" "pc_compute" {
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name
  name                = "${local.stack_id}-mi"
}

resource "azurerm_role_assignment" "pccompute" {
  scope                = data.azurerm_key_vault.deploy_secrets.id
  principal_id         = azurerm_user_assigned_identity.pc_compute.principal_id
  role_definition_name = "Key Vault Certificate User"
}
