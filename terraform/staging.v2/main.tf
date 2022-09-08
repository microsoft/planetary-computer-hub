module "resources" {
  source                 = "../resources"
  environment            = "staging"
  region                 = "West Europe"
  version_number         = "2"
  maybe_versioned_prefix = "pcc-staging-2"
  # subscription = "Planetary Computer"

  # AKS ----------------------------------------------------------------------
  kubernetes_version                                   = null
  aks_azure_active_directory_role_based_access_control = true
  aks_automatic_channel_upgrade                        = "stable"

  # 2GiB of RAM, 1 CPU core
  core_vm_size              = "Standard_A4_v2"
  core_os_disk_type         = "Managed"
  user_pool_min_count       = 1
  cpu_worker_pool_min_count = 0

  # Logs ---------------------------------------------------------------------
  workspace_id = "83dcaf36e047a90f"

  # DaskHub ------------------------------------------------------------------
  helm_chart                = "../../helm/chart.2"
  dns_label                 = "pcc-staging"
  oauth_host                = "planetarycomputer-staging"
  jupyterhub_host           = "pcc-staging.westeurope.cloudapp.azure.com"
  user_placeholder_replicas = 0
  stac_url                  = "https://planetarycomputer-staging.microsoft.com/api/stac/v1/"

  jupyterhub_singleuser_image_name = "pcccr.azurecr.io/public/planetary-computer/python"
  jupyterhub_singleuser_image_tag  = "2022.7.14.0"
  python_image                     = "pcccr.azurecr.io/public/planetary-computer/python:2022.7.14.0"
  r_image                          = "pcccr.azurecr.io/public/planetary-computer/r:2022.01.17.0"
  gpu_pytorch_image                = "pcccr.azurecr.io/public/planetary-computer/gpu-pytorch:2022.05.2.0"
  gpu_tensorflow_image             = "pcccr.azurecr.io/public/planetary-computer/gpu-tensorflow:2022.02.14.0"
  qgis_image                       = "pcccr.azurecr.io/planetary-computer/qgis:3.18.0.1"

  kbatch_proxy_url = "http://dhub-staging-kbatch-proxy.staging.svc.cluster.local"

  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
  azure_tenant_id     = var.azure_tenant_id
}

terraform {
  backend "azurerm" {
    resource_group_name  = "pc-manual-resources"
    storage_account_name = "pctfstate"
    container_name       = "pcc"
    key                  = "staging-2.tfstate"
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

