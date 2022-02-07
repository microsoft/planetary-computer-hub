resource "random_password" "test_bot_token" {
  length  = 16
  special = true
}

resource "random_password" "dask_gateway_api_token" {
  length  = 64
  special = false
  upper   = false
}

resource "helm_release" "dhub" {
  name             = "dhub-${var.environment}"
  repository       = "./charts/pchub"
  version          = "1.0.0"
  chart            = "../../helm/chart"
  namespace        = var.environment
  create_namespace = true

  values = [
    "${templatefile("../../helm/values.yaml", { jupyterhub_host = var.jupyterhub_host, namespace = var.environment })}",
    "${file("../../helm/jupyterhub_opencensus_monitor.yaml")}",
    "${templatefile("../../helm/profiles.yaml", { python_image = var.python_image, pyspark_image = var.pyspark_image, r_image = var.r_image, gpu_pytorch_image = var.gpu_pytorch_image, gpu_tensorflow_image = var.gpu_tensorflow_image, qgis_image = var.qgis_image })}",
    # workaround https://github.com/hashicorp/terraform-provider-helm/issues/669
    "${templatefile("../../helm/kbatch-proxy-values.yaml", { jupyterhub_host = var.jupyterhub_host, dns_label = var.dns_label })}",
  ]

  set {
    name  = "daskhub.jupyterhub.scheduling.userPlaceholder.replicas"
    value = var.user_placeholder_replicas
  }

  # set {
  #   name  = "daskhub.jupyterhub.hub.config.JupyterHub.api_tokens"
  #   value = "${random_password.test_bot_token.result}=pangeotestbot@microsoft.com"
  # }

  set {
    name  = "daskhub.jupyterhub.hub.config.GenericOAuthenticator.oauth_callback_url"
    value = "https://${var.jupyterhub_host}/compute/hub/oauth_callback"
  }

  set {
    name  = "daskhub.jupyterhub.hub.config.GenericOAuthenticator.client_secret"
    value = data.azurerm_key_vault_secret.id_client_secret.value
  }

  set {
    name  = "daskhub.jupyterhub.hub.extraEnv.AZURE_CLIENT_SECRET"
    value = data.azurerm_key_vault_secret.azure_client_secret.value
  }

  set {
    name  = "daskhub.jupyterhub.hub.extraEnv.PC_ID_TOKEN"
    value = data.azurerm_key_vault_secret.pc_id_token.value
  }

  set {
    name  = "daskhub.jupyterhub.hub.extraEnv.APPLICATIONINSIGHTS_CONNECTION_STRING"
    value = azurerm_application_insights.pc_compute.connection_string
  }

  set {
    name  = "daskhub.jupyterhub.hub.services.dask-gateway.apiToken"
    value = random_password.dask_gateway_api_token.result
  }

  # TODO(https://github.com/hashicorp/terraform-provider-helm/issues/628): use set-file
  # set {
  #   name = "daskhub.jupyterhub.hub.extraFiles.jupyterhub_opencensus_monitor.stringData"
  #   value = file("../../helm/chart/files/jupyterhub_opencensus_monitor.py")
  # }

  set {
    name  = "daskhub.jupyterhub.hub.services.opencensus-monitoring.environment.APPLICATIONINSIGHTS_CONNECTION_STRING"
    value = azurerm_application_insights.pc_compute.connection_string
  }

  set {
    name  = "daskhub.jupyterhub.hub.services.opencensus-monitoring.environment.JUPYTERHUB_ENVIRONMENT"
    value = var.environment
  }

  set {
    name  = "daskhub.jupyterhub.proxy.secretToken"
    value = data.azurerm_key_vault_secret.jupyterhub_proxy_secret_token.value
  }

  set {
    name  = "daskhub.jupyterhub.proxy.https.hosts"
    value = "{ ${var.jupyterhub_host} }"
  }

  set {
    name  = "daskhub.jupyterhub.proxy.service.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name"
    value = var.dns_label
  }

  set {
    name  = "daskhub.jupyterhub.singleuser.image.name"
    value = var.jupyterhub_singleuser_image_name
  }

  set {
    name  = "daskhub.jupyterhub.singleuser.image.tag"
    value = var.jupyterhub_singleuser_image_tag
  }

  set {
    name  = "daskhub.jupyterhub.singleuser.extraEnv.STAC_URL"
    value = var.stac_url
  }

  set {
    name  = "daskhub.dask-gateway.gateway.auth.jupyterhub.apiToken"
    value = random_password.dask_gateway_api_token.result
  }

  set {
    name  = "daskhub.dask-gateway.traefik.service.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name"
    value = "${var.dns_label}-dask"
  }

  # kbatch config
  # Note that kbatch-proxy.app.extra_env.KBATCH_JOB_EXTRA_ENV is set up above through values
  set {
    name  = "daskhub.jupyterhub.hub.services.kbatch.api_token"
    value = data.azurerm_key_vault_secret.kbatch_server_api_token.value
  }

  set {
    name  = "daskhub.jupyterhub.hub.services.kbatch.url"
    value = var.kbatch_proxy_url
  }

  set {
    name  = "kbatch-proxy.app.jupyterhub_api_token"
    value = data.azurerm_key_vault_secret.kbatch_server_api_token.value
  }

  set {
    name  = "kbatch-proxy.app.jupyterhub_api_url"
    value = "https://${var.jupyterhub_host}/compute/hub/api/"
  }

}

data "azurerm_storage_account" "pc-compute" {
  name                = "${replace(local.prefix, "-", "")}storage"
  resource_group_name = "${local.prefix}-shared-rg"
}

resource "kubernetes_secret" "pc-compute-fileshare" {
  metadata {
    name      = "driven-data-file-share"
    namespace = var.environment
  }

  data = {
    azurestorageaccountname = data.azurerm_storage_account.pc-compute.name
    azurestorageaccountkey  = data.azurerm_storage_account.pc-compute.primary_access_key
  }
}


# Also put it in the default namespace
# Our prod cluster seems to be having trouble getting the secret from
# the prod namespace; possibly becuase it's on an older version of Kubernetes.
resource "kubernetes_secret" "pc-compute-fileshare-default" {
  metadata {
    name = "driven-data-file-share"
  }

  data = {
    azurestorageaccountname = data.azurerm_storage_account.pc-compute.name
    azurestorageaccountkey  = data.azurerm_storage_account.pc-compute.primary_access_key
  }
}
