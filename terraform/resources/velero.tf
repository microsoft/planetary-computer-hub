resource "helm_release" "velero" {
  name             = "velero"
  repository       = "vmware-tanzu"
  version          = "2.30.1"
  chart            = "velero"
  namespace        = "velero"
  create_namespace = true

  values = [
    "${templatefile("../resources/velero_config.yaml", { subscriptionId = data.azurerm_key_vault_secret.velero_azure_subscription_id.value })}",
  ]

  set {
    name  = "credentials.secretContents.cloud"
    value = templatefile("../resources/velero_credentials.tpl", { azure_subscription_id = data.azurerm_key_vault_secret.velero_azure_subscription_id.value, azure_tenant_id = data.azurerm_key_vault_secret.velero_azure_tenant_id.value, azure_client_id = data.azurerm_key_vault_secret.velero_azure_client_id.value, azure_client_secret = data.azurerm_key_vault_secret.velero_azure_client_secret.value, azure_resource_group = azurerm_kubernetes_cluster.pc_compute.node_resource_group })
  }

}