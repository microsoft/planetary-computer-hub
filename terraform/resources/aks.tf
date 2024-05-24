resource "azurerm_kubernetes_cluster" "pc_compute" {
  name                      = "${var.maybe_versioned_prefix}-cluster"
  location                  = azurerm_resource_group.pc_compute.location
  resource_group_name       = azurerm_resource_group.pc_compute.name
  dns_prefix                = "${var.maybe_versioned_prefix}-cluster"
  kubernetes_version        = var.kubernetes_version
  sku_tier                  = "Standard"
  automatic_channel_upgrade = var.aks_automatic_channel_upgrade

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # https://learn.microsoft.com/en-us/azure/aks/auto-upgrade-node-os-image
  node_os_channel_upgrade = "NodeImage"
  # https://learn.microsoft.com/en-us/azure/aks/image-cleaner
  image_cleaner_enabled = true

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.pc_compute.id
  }

  microsoft_defender {
    log_analytics_workspace_id = data.azurerm_key_vault_secret.microsoft_defender_log_analytics_workspace_id.value
  }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  # Core node-pool
  default_node_pool {
    name            = "core"
    vm_size         = var.core_vm_size
    os_sku          = "AzureLinux"
    os_disk_size_gb = 100
    # Managed for staging, since A-series VM don't support Ephemeral
    os_disk_type        = var.core_os_disk_type
    enable_auto_scaling = true
    node_count          = 1
    min_count           = 1
    max_count           = 1
    vnet_subnet_id      = azurerm_subnet.node_subnet.id
    node_labels = {
      "hub.jupyter.org/node-purpose" = "core"
    }

    orchestrator_version        = var.kubernetes_version
    temporary_name_for_rotation = "azlinuxpool"

    upgrade_settings {
      max_surge = "10%"
    }

  }

  auto_scaler_profile {
    empty_bulk_delete_max       = "50"
    scale_down_unready          = "2m"
    scale_down_unneeded         = "2m"
    scale_down_delay_after_add  = "5m"
    skip_nodes_with_system_pods = false # ensures system pods don't keep GPU nodes alive
  }

  ingress_application_gateway {
    gateway_id = data.azurerm_application_gateway.pc_compute.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "AI4E"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user_pool" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.pc_compute.id
  vm_size               = var.user_vm_size
  os_sku                = "AzureLinux"
  enable_auto_scaling   = true
  os_disk_size_gb       = 200
  node_taints           = ["hub.jupyter.org_dedicated=user:NoSchedule"]
  vnet_subnet_id        = azurerm_subnet.node_subnet.id

  orchestrator_version = var.kubernetes_version
  node_labels = {
    "hub.jupyter.org/pool-name"    = "user-alpha-pool",
    "hub.jupyter.org/node-purpose" = "user",
  }

  min_count = var.user_pool_min_count
  max_count = 100

  zones = []

  tags = {
    Environment = "Production"
    ManagedBy   = "AI4E"
  }

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }

}


resource "azurerm_kubernetes_cluster_node_pool" "cpu_worker_pool" {
  name                  = "cpuworker"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.pc_compute.id
  vm_size               = var.cpu_worker_vm_size
  os_sku                = "AzureLinux"
  enable_auto_scaling   = true
  os_disk_size_gb       = 128
  orchestrator_version  = var.kubernetes_version
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = -1
  vnet_subnet_id        = azurerm_subnet.node_subnet.id

  node_labels = {
    "k8s.dask.org/dedicated"                = "worker",
    "pc.microsoft.com/workerkind"           = "cpu",
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }

  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule",
  ]

  min_count = var.cpu_worker_pool_min_count
  max_count = var.cpu_worker_max_count
  tags = {
    Environment = "Production"
    ManagedBy   = "AI4E"
  }

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }

}

# Workload Identity for hub access to API Management
resource "azurerm_user_assigned_identity" "hub" {
  name                = "id-${local.maybe_staging_prefix}"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name
}

# Give the hub identity access to the API Management service
resource "azurerm_role_assignment" "hub-identity-apim-contributor" {
  scope                = var.apim_resource_id
  role_definition_name = "API Management Service Contributor"
  principal_id         = azurerm_user_assigned_identity.hub.principal_id
}

# Create a FIC to map the hub identity into the service account that is used by the hub
resource "azurerm_federated_identity_credential" "hub" {
  name                = "federated-id-${local.maybe_staging_prefix}"
  resource_group_name = azurerm_resource_group.pc_compute.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.pc_compute.oidc_issuer_url
  subject             = "system:serviceaccount:${var.environment}:hub"
  parent_id           = azurerm_user_assigned_identity.hub.id
  timeouts {}
}
