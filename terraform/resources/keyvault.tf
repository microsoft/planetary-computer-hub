data "azurerm_key_vault" "deploy_secrets" {
  name                = var.pc_resources_kv
  resource_group_name = var.pc_resources_rg
  provider            = azurerm.pc
}

data "azurerm_key_vault" "certificate" {
  name                = var.certificate_kv
  resource_group_name = var.certificate_kv_rg
}


data "azurerm_key_vault" "test_deploy_secrets" {
  name                = "pc-test-deploy-secrets"
  resource_group_name = "pc-test-manual-resources"
  provider            = azurerm.pct
}

# JupyterHub
data "azurerm_key_vault_secret" "jupyterhub_proxy_secret_token" {
  name         = "${local.namespaced_prefix}--jupyterhub-proxy-secret-token"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

# Django App

data "azurerm_key_vault_secret" "id_client_secret" {
  name         = "${local.stack_id}--id-client-secret"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

data "azurerm_key_vault_secret" "pc_id_token" {
  name         = "${local.stack_id}--pc-id-token"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

data "azurerm_key_vault_secret" "microsoft_defender_log_analytics_workspace_id" {
  name         = "${local.stack_id}--microsoft-defender-log-analytics-workspace-id"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

data "azurerm_key_vault_certificate" "pccompute" {
  name         = "planetarycomputer-hub-test"
  key_vault_id = data.azurerm_key_vault.test_deploy_secrets.id
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "secret-reader" {
  key_vault_id = data.azurerm_key_vault.test_deploy_secrets.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.pc_compute.key_vault_secrets_provider[0].secret_identity[0].object_id

  secret_permissions = [
    "Get",
  ]
  certificate_permissions = [
    "Get",
  ]
  key_permissions = [
    "Get",
  ]
}
