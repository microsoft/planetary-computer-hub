module "resources" {
  source                 = "../resources"
  environment            = "prod"
  region                 = "West Europe"
  version_number         = "2"
  maybe_versioned_prefix = "pcc-prod-2"
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
  workspace_id = "225cedbd199c55da"

  # DaskHub ------------------------------------------------------------------
  dns_label                 = "pccompute"
  oauth_host                = "planetarycomputer"
  jupyterhub_host           = "pccompute.westeurope.cloudapp.azure.com"
  user_placeholder_replicas = 1
  stac_url                  = "https://planetarycomputer.microsoft.com/api/stac/v1/"

  jupyterhub_singleuser_image_name = "pcccr.azurecr.io/planetary-computer/python"
  jupyterhub_singleuser_image_tag  = "2024.3.19.2"
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
    key                  = "prod-2.tfstate" # TODO: migrate to prod.tfstate
  }
}

output "resources" {
  value     = module.resources
  sensitive = true
}

# We require this, since we used to generate the pcccr ACR
provider "azurerm" {
  features {}
}
