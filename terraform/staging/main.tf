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
  dns_label                 = "pcc-staging"
  oauth_host                = "planetarycomputer-staging"
  jupyterhub_host           = "pcc-staging.westeurope.cloudapp.azure.com"
  user_placeholder_replicas = 0
  stac_url                  = "https://planetarycomputer-staging.microsoft.com/api/stac/v1/"

  jupyterhub_singleuser_image_name = "pcccr.azurecr.io/planetary-computer/python"
  jupyterhub_singleuser_image_tag  = "2024.3.20.1"
  python_image                     = "pcccr.azurecr.io/planetary-computer/python:2024.3.20.1"
  r_image                          = "pcccr.azurecr.io/planetary-computer/r:2024.3.20.1"
  gpu_pytorch_image                = "pcccr.azurecr.io/planetary-computer/gpu-pytorch:2024.3.20.2"
  gpu_tensorflow_image             = "pcccr.azurecr.io/planetary-computer/gpu-tensorflow:2024.3.20.1"
  qgis_image                       = "pcccr.azurecr.io/planetary-computer/qgis:2024.3.19.7"

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
