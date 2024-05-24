module "resources" {
  source                 = "../resources"
  environment            = "test"
  region                 = "West Europe"
  version_number         = "2"
  maybe_versioned_prefix = "pcc-test"

  apim_resource_id = "/subscriptions/9da7523a-cb61-4c3e-b1d4-afa5fc6d2da9/resourceGroups/pc-manual-resources/providers/Microsoft.ApiManagement/service/planetarycomputer"
  # TLS certs
  certificate_kv          = "pc-test-deploy-secrets"
  certificate_kv_rg       = "pc-test-manual-resources"
  certificate_secret_name = "planetarycomputer-hub-test"
  pip_name                = "pccompute-public-ip"
  appgw_name              = "pccompute-appgateway"

  # AKS ----------------------------------------------------------------------
  kubernetes_version                                   = null
  aks_azure_active_directory_role_based_access_control = true
  aks_automatic_channel_upgrade                        = "rapid"

  # 2GiB of RAM, 1 CPU core
  core_vm_size              = "Standard_A4_v2"
  core_os_disk_type         = "Managed"
  user_pool_min_count       = 1
  cpu_worker_pool_min_count = 0

  # Logs ---------------------------------------------------------------------
  workspace_id = "83dcaf36e047a90f"

  # DaskHub ------------------------------------------------------------------
  dns_label                 = "planetarycomputer-hub-test"
  oauth_host                = "planetarycomputer-staging"
  jupyterhub_host           = "planetarycomputer-hub-test.microsoft.com"
  user_placeholder_replicas = 0
  stac_url                  = "https://planetarycomputer-staging.microsoft.com/api/stac/v1/"

  jupyterhub_singleuser_image_name = "pcccr.azurecr.io/planetary-computer/python"
  jupyterhub_singleuser_image_tag  = "2024.3.20.1"
  python_image                     = "pcccr.azurecr.io/planetary-computer/python:2024.3.20.1"
  r_image                          = "pcccr.azurecr.io/planetary-computer/r:2024.3.20.1"
  gpu_pytorch_image                = "pcccr.azurecr.io/planetary-computer/gpu-pytorch:2024.3.22.0"
  gpu_tensorflow_image             = "pcccr.azurecr.io/planetary-computer/gpu-tensorflow:2024.3.22.0"
  qgis_image                       = "pcccr.azurecr.io/planetary-computer/qgis:2024.3.19.7"
}

terraform {
  backend "azurerm" {
    resource_group_name  = "pc-test-manual-resources"
    storage_account_name = "pctesttfstate"
    container_name       = "pcc"
    key                  = "pcc.tfstate"
  }
}

output "resources" {
  value     = module.resources
  sensitive = true
}
