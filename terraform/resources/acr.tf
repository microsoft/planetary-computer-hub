# This is some leftover cruft from the common -> staging / prod split.
# We want to re-use the ACR that was originally created under common.
# We'll keep managing the actual ACR with prod, and will attach it
# here (in resources) for staging and prod.

# If deploying for the first time, you might put it in a manual resource
# and just use the ID, like we're doing below, or use a separate
# ACR per environment.

# resource "azurerm_container_registry" "container_registry" {
#   name                = "${local.stack_id}cr"
#   resource_group_name = azurerm_resource_group.pc_compute.name
#   location            = azurerm_resource_group.pc_compute.location
#   sku                 = "premium"
#   admin_enabled       = true
# }

# add the role to the identity the kubernetes cluster was assigned
resource "azurerm_role_assignment" "attach_acr" {
  # scope                = azurerm_container_registry.container_registry.id
  scope                = "/subscriptions/9da7523a-cb61-4c3e-b1d4-afa5fc6d2da9/resourceGroups/pcc-westeurope-rg/providers/Microsoft.ContainerRegistry/registries/pcccr"
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.pc_compute.kubelet_identity[0].object_id
}
