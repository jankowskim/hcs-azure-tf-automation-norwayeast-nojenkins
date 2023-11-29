resource "random_id" "log_analytics_workspace_name_suffix" {
    byte_length = 8
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.hex}"
  location            = var.location
  resource_group_name = module.rg_hcs.name
  sku                 = var.log_analytics_workspace_sku
  tags                       = merge(local.hcs_tags, {})
}

resource "azurerm_log_analytics_solution" "log_analytics_solution" {
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = module.rg_hcs.name
  workspace_resource_id = azurerm_log_analytics_workspace.log_analytics.id
  workspace_name        = azurerm_log_analytics_workspace.log_analytics.name
  tags                       = merge(local.hcs_tags, {})

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
