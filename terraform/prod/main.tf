module "resources" {
  source      = "../resources"
  environment = "prod"
  region      = "West Europe"
  # subscription = "Planetary Computer"

  # AKS ----------------------------------------------------------------------
  kubernetes_version = "1.19.7"
  # 8GB of RAM, 4 CPU cores, ssd base disk
  core_vm_size              = "Standard_E4s_v3"
  user_pool_min_count       = 1
  cpu_worker_pool_min_count = 1

  # Logs ---------------------------------------------------------------------
  workspace_id = "225cedbd199c55da"

  # DaskHub ------------------------------------------------------------------
  dns_label                        = "pccompute"
  jupyterhub_host                  = "pccompute.westeurope.cloudapp.azure.com"
  user_placeholder_replicas        = 1
  stac_url                         = "https://planetarycomputer.microsoft.com/api/stac/v1/"
  jupyterhub_singleuser_image_name = "mcr.microsoft.com/planetary-computer/python"
  jupyterhub_singleuser_image_tag  = "2021.09.23.1"
  python_image                     = "mcr.microsoft.com/planetary-computer/python:2021.09.23.1"
  r_image                          = "mcr.microsoft.com/planetary-computer/r:2021.09.22.0"
  gpu_pytorch_image                = "mcr.microsoft.com/planetary-computer/gpu-pytorch:2021.09.23.1"
  qgis_image                       = "pcccr.azurecr.io/planetary-computer/qgis:3.18.0"

}

terraform {
  backend "azurerm" {
    resource_group_name  = "pc-manual-resources"
    storage_account_name = "pctfstate"
    container_name       = "pcc"
    key                  = "common.tfstate" # TODO: migrate to prod.tfstate
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

