terraform {
  required_version = ">=1.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
  }
}

provider "azurerm" {
  features {
    subscription_id = "1a8a30e4-894b-4f2c-9315-edb4fc5a31db"
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
data "azurerm_kubernetes_cluster" "existing_aks" {
  name                = "aks-hcs001-norwayeast"
  resource_group_name = "rg-hcs-norwayeast-dev"
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.existing_aks.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.existing_aks.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.existing_aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.existing_aks.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.existing_aks.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.existing_aks.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.existing_aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.existing_aks.kube_config.0.cluster_ca_certificate)
}

