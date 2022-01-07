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
  dns_label                 = "pccompute"
  jupyterhub_host           = "pccompute.westeurope.cloudapp.azure.com"
  user_placeholder_replicas = 1
  stac_url                  = "https://planetarycomputer.microsoft.com/api/stac/v1/"

  jupyterhub_singleuser_image_name = "pcccr.azurecr.io/public/planetary-computer/python"
  jupyterhub_singleuser_image_tag  = "2022.01.17.0"
  python_image                     = "pcccr.azurecr.io/public/planetary-computer/python:2022.01.17.0"
  pyspark_image                    = "daunnc/planetary-computer-pyspark:2021.11.29.0-gdal3.4-3.1-rf"
  r_image                          = "pcccr.azurecr.io/public/planetary-computer/r:2022.01.17.0"
  gpu_pytorch_image                = "pcccr.azurecr.io/public/planetary-computer/gpu-pytorch:2022.01.17.0"
  gpu_tensorflow_image             = "pcccr.azurecr.io/public/planetary-computer/gpu-tensorflow:2022.01.17.0"
  qgis_image                       = "pcccr.azurecr.io/planetary-computer/qgis:3.18.0.1"

  kbatch_proxy_url = "http://dhub-prod-kbatch-proxy.prod.svc.cluster.local"
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

