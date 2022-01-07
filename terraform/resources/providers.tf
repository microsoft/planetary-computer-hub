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
    # config_path            = "~/.kube/config"
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.pc_compute.kube_config[0].host
  client_key             = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].client_key)
  client_certificate     = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].client_certificate)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].cluster_ca_certificate)
  # config_path            = "~/.kube/config"
}


terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.74.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.6.1"
    }

  }
}
