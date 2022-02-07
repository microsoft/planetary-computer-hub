resource "azurerm_kubernetes_cluster" "pc_compute" {
  name                = "${local.maybe_staging_prefix}-cluster"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name
  dns_prefix          = "${local.maybe_staging_prefix}-cluster"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Paid"
  
  role_based_access_control {
    enabled = var.enable_role_based_access_control
  }

  addon_profile {
    kube_dashboard {
      enabled = false
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.pc_compute.id
    }
  }

  # Core node-pool
  default_node_pool {
    name            = "core"
    vm_size         = var.core_vm_size
    os_disk_size_gb = 100
    # Managed for staging, since A-series VM don't support Ephemeral
    os_disk_type        = var.environment == "staging" ? "Managed" : "Ephemeral"
    enable_auto_scaling = true
    node_count          = 1
    min_count           = 1
    max_count           = 1
    vnet_subnet_id      = azurerm_subnet.node_subnet.id
    node_labels = {
      "hub.jupyter.org/node-purpose" = "core"
    }

    orchestrator_version = var.kubernetes_version
  }

  auto_scaler_profile {
    empty_bulk_delete_max       = "50"
    scale_down_unready          = "2m"
    scale_down_unneeded         = "2m"
    scale_down_delay_after_add  = "5m"
    skip_nodes_with_system_pods = false # ensures system pods don't keep GPU nodes alive
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

  availability_zones = []

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

# Spark supports pool with no taints and can select nodes via selector only by default
# https://spark.apache.org/docs/latest/running-on-kubernetes.html#how-it-works
# We use a non default spark-executors template to address this issue
resource "azurerm_kubernetes_cluster_node_pool" "spark_cpu_worker_pool" {
  name                  = "spcpuworker"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.pc_compute.id
  vm_size               = var.cpu_worker_vm_size
  enable_auto_scaling   = true
  os_disk_size_gb       = 128
  orchestrator_version  = var.kubernetes_version
  priority              = "Spot" # Regular when not set
  eviction_policy       = "Delete"
  spot_max_price        = -1
  vnet_subnet_id        = azurerm_subnet.node_subnet.id

  node_labels = {
    "k8s.spark.org/dedicated"               = "worker",
    "pc.microsoft.com/workerkind"           = "spark-cpu",
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
