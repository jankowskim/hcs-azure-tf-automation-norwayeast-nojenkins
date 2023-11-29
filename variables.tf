variable "env" {
  description = "Customer Env"
  type        = string
}

variable "env_shSrv" {
  description = "shSrv Env"
  type        = string
}

variable "customer_name" {
  type = string
}

variable "domain" {
  description = "Domain to be used"
  type        = string
}

variable "location" {
  description = "The Azure location identifier such as eastus2"
  type        = string
}

variable "location_shSrv" {
  description = "The Azure location identifier for Shared Services such as eastus2"
  type        = string
}

variable "deployment_id" {
  description = "Customer Deployment id"
  type        = string
}

variable "existing_subscription_id" {
  description = "New Subscription id to be used for envs"
  type        = string
  default     = ""
}

variable "offer_code" {
  description = "Prefix to be used in subscription name. Ex: ec, ecpl, ecplsh"
  type        = string
  default     = "ec"
}

variable "skip_sentinel_policy" {
  description = "If set to true, sentinel policy will be skipped and pass irrespective of its actual result"
  type        = bool
  default     = false
}

variable "zones" {
  description = "List of zones to be used"
  type        = list(any)
}

variable "shsrv_artifacts_sa_contanier_name" {
  description = "Shared Services artifacts storage account container name"
  type        = string
  default     = "artifacts"
}

variable "storage_account_type" {
  description = "Storage Account Type"
  type        = string
  default     = "Premium_LRS"
}

variable "caching" {
  description = "Caching"
  type        = string
  default     = "ReadWrite"
}

variable "vnet_hcs" {
  description = "Parameters to configure VNET"
  type = object({
    name                    = string
    address_spaces          = list(string)
    dns_servers             = list(string)
    ddos_protection_plan_id = string
    subnets = map(object({
      address_prefixes                              = list(string)
      service_endpoints                             = list(string)
      private_endpoint_network_policies_enabled     = bool
      private_link_service_network_policies_enabled = bool
      delegation = list(object({
        name = string
        service_delegation = object({
          name    = string
          actions = list(string)
        })
      }))
    }))
    peerings = list(object({
      hub_resource_group_name           = string
      hub_vnet_name                     = string
      hub_vnet_id                       = string
      name_to_spoke                     = string
      allow_vnet_access_hub_spoke       = bool
      allow_forwarded_traffic_hub_spoke = bool
      allow_gateway_transit_hub_spoke   = bool
      use_remote_gateways_hub_spoke     = bool
      name_to_hub                       = string
      allow_vnet_access_spoke_hub       = bool
      allow_forwarded_traffic_spoke_hub = bool
      allow_gateway_transit_spoke_hub   = bool
      use_remote_gateways_spoke_hub     = bool
    }))
  })
}

# k8s variables
variable "k8s_cluster_name" {
  type        = string
  description = "kubernetes cluster name"
}

variable "k8s_version" {
  type        = string
  description = "kubernetes version"
}

variable "k8s_vm_size" {
  type        = string
  description = "kubernetes VM size"
  default     = "Standard_D8s_v5"
}

variable "k8s_node_count" {
  type        = string
  description = "kubernetes node count"
  default     = 3
}

variable "k8s_node_min_count" {
  type        = string
  description = "kubernetes node min count"
  default     = 3
}

variable "k8s_node_max_count" {
  type        = string
  description = "kubernetes node max count"
  default     = 24
}

variable "k8s_auto_scaling_enabled" {
  type        = bool
  description = "kubernetes enable auto scaling"
  default     = true
}

variable "k8s_public_ip_enabled" {
  type        = bool
  description = "kubernetes enable public ip"
  default     = false
}

variable "k8s_dns_service_ip" {
  type        = string
  description = "kubernetes dns service ip"
  default     = "192.168.0.10"
}

variable "k8s_dns_prefix" {
  type        = string
  description = "kubernetes dns prefix"
  default     = "hcs-private"
}

variable "k8s_service_cidr" {
  type        = string
  description = "kubernetes service cidr"
  default     = "192.168.0.0/18"
}

variable "k8s_pod_cidr" {
  type        = string
  description = "kubernetes pod cidr"
  default     = "192.168.64.0/18"
}

variable "k8s_network_plugin" {
  type        = string
  description = "kubernetes network plugin"
  default     = "kubenet"
}

variable "k8s_network_policy" {
  type        = string
  description = "kubernetes network policy"
  default     = "calico"
}

variable "k8s_max_pods" {
  type        = string
  description = "kubernetes max pods"
  default     = "110"
}

variable "k8s_admin_username" {
  type        = string
  description = "kubernetes admin username"
  default     = "brix"
}

# log analytics variables
variable log_analytics_workspace_name {
    default = "HCS-LogAnalyticsWorkspace"
}

variable log_analytics_workspace_sku {
    default = "PerGB2018"
}

variable "data_collection_interval" {
  default = "1m"
}

variable "namespace_filtering_mode_for_data_collection" {
  default = "Off"
}

variable "namespaces_for_data_collection" {
  default = ["kube-system", "gatekeeper-system", "azure-arc"]
}

variable "enableContainerLogV2" {
  default = true
}

variable "streams" {
 default = ["Microsoft-ContainerLog", "Microsoft-ContainerLogV2", "Microsoft-KubeEvents", "Microsoft-KubePodInventory", "Microsoft-KubeNodeInventory", "Microsoft-KubePVInventory","Microsoft-KubeServices", "Microsoft-KubeMonAgentEvents", "Microsoft-InsightsMetrics", "Microsoft-ContainerInventory",  "Microsoft-ContainerNodeInventory", "Microsoft-Perf"]
}

# appgw variables
variable "appgw_sku" {
  type        = string
  description = "Application Gateway SKU"
  default     = "WAF_v2"
}

variable "appgw_frontend_cert_name" {
  type        = string
  description = "Application Gateway Frontend Certificate Name"
  default     = "appgw-frontend-cert"
}
