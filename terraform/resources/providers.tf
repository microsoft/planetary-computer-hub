provider "azurerm" {
  features {}
}

provider "helm" {
  # https://dev.to/danielepolencic/getting-started-with-terraform-and-kubernetes-on-azure-aks-3l4d
  kubernetes {
    host                   = azurerm_kubernetes_cluster.pc_compute.kube_config[0].host
    client_key             = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].client_key)
    client_certificate     = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].client_certificate)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].cluster_ca_certificate)

    # TODO(migration): remove remove this and just set to content
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      # Note: The AAD server app ID of AKS Managed AAD is always 6dae42f8-4368-4678-94ff-3960e28e3630 in any environments.
      # See https://github.com/Azure/kubelogin#exec-plugin-format
      args    = ["get-token", "--environment", "AzurePublicCloud", "--client-id", var.azure_client_id, "--client-secret", var.azure_client_secret, "--tenant-id", var.azure_tenant_id, "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
      command = "kubelogin"
    }

  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.pc_compute.kube_config[0].host
  client_key             = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].client_key)
  client_certificate     = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].client_certificate)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].cluster_ca_certificate)

  # TODO(migration): remove remove this and just set to content
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    # Note: The AAD server app ID of AKS Managed AAD is always 6dae42f8-4368-4678-94ff-3960e28e3630 in any environments.
    # See https://github.com/Azure/kubelogin#exec-plugin-format
    args    = ["get-token", "--environment", "AzurePublicCloud", "--client-id", var.azure_client_id, "--client-secret", var.azure_client_secret, "--tenant-id", var.azure_tenant_id, "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
    command = "kubelogin"
  }

  # # TODO(migration): remove remove this and just set to content
  # dynamic "exec" {
  #   for_each = [for b in [var.aks_azure_active_directory_role_based_access_control] : b if b]
  #   content {
  #     api_version = "client.authentication.k8s.io/v1beta1"
  #     # Note: The AAD server app ID of AKS Managed AAD is always 6dae42f8-4368-4678-94ff-3960e28e3630 in any environments.
  #     # See https://github.com/Azure/kubelogin#exec-plugin-format
  #     args    = ["get-token", "--environment", "AzurePublicCloud", "--client-id", var.azure_client_id, "--client-secret", var.azure_client_secret, "--tenant-id", var.azure_tenant_id, "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
  #     command = "kubelogin"
  #   }
  # }

}


terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.99.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }

  }
}
