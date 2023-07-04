module "resources" {
  source                 = "../resources"
  environment            = "staging"
  region                 = "West Europe"
  version_number         = "2"
  maybe_versioned_prefix = "dep-staging"
  # subscription = "Planetary Computer"

  # AKS ----------------------------------------------------------------------
  kubernetes_version                                   = null
  aks_azure_active_directory_role_based_access_control = true
  aks_automatic_channel_upgrade                        = "stable"

  # 8GB of RAM, 4 CPU cores, ssd base disk
  core_vm_size              = "Standard_E4s_v3"
  core_os_disk_type         = "Ephemeral"
  user_pool_min_count       = 1
  cpu_worker_pool_min_count = 1

  # Logs ---------------------------------------------------------------------
  workspace_id = "83dcaf36e047a90f"

  # DaskHub ------------------------------------------------------------------
  dns_label                 = "dep-staging"
  oauth_host                = "dep-staging"
  jupyterhub_host           = "dep-staging.westeurope.cloudapp.azure.com"
  user_placeholder_replicas = 0
  stac_url                  = "https://planetarycomputer.microsoft.com/api/stac/v1/"

  jupyterhub_singleuser_image_name = "pcccr.azurecr.io/public/planetary-computer/python"
  jupyterhub_singleuser_image_tag  = "2023.5.3.0"
  python_image                     = "pcccr.azurecr.io/public/planetary-computer/python:2023.5.3.0"
  r_image                          = "pcccr.azurecr.io/public/planetary-computer/r:2023.1.30.0"
  gpu_pytorch_image                = "pcccr.azurecr.io/public/planetary-computer/gpu-pytorch:2022.9.16.0"
  gpu_tensorflow_image             = "pcccr.azurecr.io/public/planetary-computer/gpu-tensorflow:2022.9.16.0"
  qgis_image                       = "pcccr.azurecr.io/planetary-computer/qgis:3.18.0.1"

  kbatch_proxy_url = "http://dhub-staging-kbatch-proxy.staging.svc.cluster.local"

  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
  azure_tenant_id     = var.azure_tenant_id
  pc_resources_kv     = var.pc_resources_kv
  pc_resources_rg     = var.pc_resources_rg
}

terraform {
  backend "azurerm" {
    resource_group_name  = "dep-staging"
    storage_account_name = "depstagingterraform"
    container_name       = "dep-staging-state"
    key                  = "shared.tfstate"
  }
}

output "resources" {
  value     = module.resources
  sensitive = true
}

variable "azure_client_id" {
  type = string
}
variable "azure_client_secret" {
  type = string
}
variable "azure_tenant_id" {
  type = string
}
variable "pc_resources_kv" {
  type = string
}
variable "pc_resources_rg" {
  type = string
}
