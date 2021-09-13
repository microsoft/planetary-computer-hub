output "environment" {
  value = var.environment
}

output "location" {
  value = local.location
}

output "id_client_secret" {
  value     = data.azurerm_key_vault_secret.id_client_secret.value
  sensitive = true
}

output "azure_client_secret" {
  value     = data.azurerm_key_vault_secret.azure_client_secret.value
  sensitive = true
}

output "pc_id_token" {
  value     = data.azurerm_key_vault_secret.pc_id_token.value
  sensitive = true
}

output "jupyterhub_proxy_secret_token" {
  value     = data.azurerm_key_vault_secret.jupyterhub_proxy_secret_token.value
  sensitive = true
}

# TODO(Tom): verify jupyterhub_host is used
output "jupyterhub_host" {
  value = var.jupyterhub_host
}

output "stac_url" {
  value = var.stac_url
}

output "user_placeholder_replicas" {
  value = var.user_placeholder_replicas
}

output "kubeconfig" {
  value     = azurerm_kubernetes_cluster.pc_compute.kube_config_raw
  sensitive = true
}