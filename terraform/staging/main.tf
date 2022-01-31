module "resources" {
  source      = "../resources"
  environment = "staging"
  region      = "West Europe"
  # subscription = "Planetary Computer"

  # AKS ----------------------------------------------------------------------
  kubernetes_version = "1.21.2"
  # 2GiB of RAM, 1 CPU core
  core_vm_size              = "Standard_A2_v2"
  user_pool_min_count       = 1
  cpu_worker_pool_min_count = 0

  # Logs ---------------------------------------------------------------------
  workspace_id = "83dcaf36e047a90f"

  # DaskHub ------------------------------------------------------------------
  dns_label                 = "pcc-staging"
  jupyterhub_host           = "pcc-staging.westeurope.cloudapp.azure.com"
  user_placeholder_replicas = 0
  stac_url                  = "https://planetarycomputer-staging.microsoft.com/api/stac/v1/"

  jupyterhub_singleuser_image_name = "pcccr.azurecr.io/public/planetary-computer/python"
  jupyterhub_singleuser_image_tag  = "2022.01.31.0"
  python_image                     = "pcccr.azurecr.io/public/planetary-computer/python:2022.01.31.0"
  pyspark_image                    = "daunnc/planetary-computer-pyspark:2021.11.29.0-gdal3.4-3.1-rf"
  r_image                          = "pcccr.azurecr.io/public/planetary-computer/r:2022.01.17.0"
  gpu_pytorch_image                = "pcccr.azurecr.io/public/planetary-computer/gpu-pytorch:2022.01.17.0"
  gpu_tensorflow_image             = "pcccr.azurecr.io/public/planetary-computer/gpu-tensorflow:2022.01.17.0"
  qgis_image                       = "pcccr.azurecr.io/planetary-computer/qgis:3.18.0.1"

  kbatch_proxy_url = "http://dhub-staging-kbatch-proxy.staging.svc.cluster.local"
}

terraform {
  backend "azurerm" {
    resource_group_name  = "pc-manual-resources"
    storage_account_name = "pctfstate"
    container_name       = "pcc"
    key                  = "staging.tfstate"
  }
}

output "resources" {
  value     = module.resources
  sensitive = true
}
