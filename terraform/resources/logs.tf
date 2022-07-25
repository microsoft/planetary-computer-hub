# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_solution

resource "azurerm_log_analytics_workspace" "pc_compute" {
  name                = "${local.prefix}-workspace-${var.workspace_id}"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name
  sku                 = "PerGB2018"
  tags                = {}
}

resource "azurerm_log_analytics_solution" "pc_compute" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.pc_compute.location
  resource_group_name   = azurerm_resource_group.pc_compute.name
  workspace_resource_id = azurerm_log_analytics_workspace.pc_compute.id
  workspace_name        = azurerm_log_analytics_workspace.pc_compute.name

  tags = {}

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_application_insights" "pc_compute" {
  name                = "pc-compute-appinsights"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name
  application_type    = "other"
  tags                = {}
}
