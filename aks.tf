resource "azurerm_kubernetes_cluster" "hcs_k8s" {
  name                          = "aks-${var.k8s_cluster_name}-${var.location}"
  location                      = var.location
  resource_group_name           = module.rg_hcs.name
  kubernetes_version            = var.k8s_version
  automatic_channel_upgrade     = "patch"
  #dns_prefix_private_cluster    = "aks-${var.k8s_dns_prefix}"
  private_cluster_enabled       = true
  dns_prefix                    = "aks-${var.k8s_dns_prefix}"
  node_resource_group           = "aks-nodepool-${var.k8s_cluster_name}-${var.location}"
  sku_tier                      = "Standard"
  tags                          = merge(local.hcs_tags, {})

  network_profile {
    network_plugin              = var.k8s_network_plugin
    network_policy              = var.k8s_network_policy
    service_cidr                = var.k8s_service_cidr
    pod_cidr                    = var.k8s_pod_cidr
    dns_service_ip              = var.k8s_dns_service_ip
  }

  default_node_pool {
    name                        = "system"
    vnet_subnet_id              = module.vnet-hcs.subnets["snet-hcs001"].subnet_ids
    type                        = "VirtualMachineScaleSets"
    zones                       = var.zones
    node_count                  = var.k8s_node_count
    min_count                   = var.k8s_node_min_count
    max_count                   = var.k8s_node_max_count
    max_pods                    = var.k8s_max_pods
    enable_auto_scaling         = var.k8s_auto_scaling_enabled
    vm_size                     = var.k8s_vm_size
    enable_node_public_ip       = false
    tags                        = merge(local.hcs_tags, {})

    node_labels = {
      "worker-name" = "system-${var.k8s_cluster_name}-${var.location}"
    }
  }

  linux_profile {
    admin_username = var.k8s_admin_username

    ssh_key {
      key_data = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
    msi_auth_for_monitoring_enabled = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks_cluster" {
  name                       = "${azurerm_kubernetes_cluster.hcs_k8s.name}-audit"
  target_resource_id         = azurerm_kubernetes_cluster.hcs_k8s.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }
}

resource "azurerm_monitor_data_collection_rule" "hcs_dcr" {
  name                = "MSCI-${var.location}-${var.k8s_cluster_name}-${var.location}"
  location            = var.location
  resource_group_name = module.rg_hcs.name
  tags                = merge(local.hcs_tags, {})

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.log_analytics.id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = var.streams
    destinations = ["ciworkspace"]
  }

  data_sources {
    extension {
      streams            = var.streams
      extension_name     = "ContainerInsights"
      extension_json     = jsonencode({
        "dataCollectionSettings" : {
            "interval": var.data_collection_interval,
            "namespaceFilteringMode": var.namespace_filtering_mode_for_data_collection,
            "namespaces": var.namespaces_for_data_collection
            "enableContainerLogV2": var.enableContainerLogV2
        }
      })
      name               = "ContainerInsightsExtension"
    }
  }

  description = "DCR for Azure Monitor Container Insights"
}

resource "azurerm_monitor_data_collection_rule_association" "dcra" {
  name                        = "ContainerInsightsExtension"
  target_resource_id          = azurerm_kubernetes_cluster.hcs_k8s.id
  data_collection_rule_id     = azurerm_monitor_data_collection_rule.hcs_dcr.id
  description                 = "Association of container insights data collection rule. Deleting this association will break the data collection for this AKS Cluster."
}
