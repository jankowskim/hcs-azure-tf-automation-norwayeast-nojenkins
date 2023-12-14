offer_code                          = "ec"
deployment_id                       = "avaya01"
customer_name                       = "avayahcs"
domain                              = "ec.avayacloud.com"
location                            = "swedencentral"
location_shSrv                      = "swedencentral"
zones                               = ["1", "2", "3"]
env                                 = "dev"
env_shSrv                           = "nonprod"
shsrv_artifacts_sa_contanier_name   = ""
storage_account_type                = "Premium_LRS"
caching                             = "ReadWrite"
skip_sentinel_policy                = false
# aks
k8s_cluster_name                    = "hcs001"
k8s_version                         = "1.27"
k8s_vm_size                         = "Standard_D8s_v5"
k8s_node_count                      = 3
k8s_node_min_count                  = 3
k8s_node_max_count                  = 24
k8s_max_pods                        = 110
k8s_auto_scaling_enabled            = true
k8s_public_ip_enabled               = false
k8s_network_plugin                  = "kubenet"
k8s_network_policy                  = "calico"
k8s_service_cidr                    = "192.168.0.0/18"
k8s_dns_service_ip                  = "192.168.0.10"
k8s_dns_prefix                      = "hcs-private"
k8s_pod_cidr                        = "192.168.64.0/18"
k8s_admin_username                  = "brix"
# appgw
appgw_sku                           = "WAF_v2"
appgw_frontend_cert_name            = "appgw-frontend-cert"

vnet_hcs = {
  name                    = "vnet-hcs"
  address_spaces          = ["172.16.0.0/22"]
  dns_servers             = []
  ddos_protection_plan_id = ""
  subnets = {
    snet-dnsiep = {
      address_prefixes                              = ["172.16.1.0/28", ]
      service_endpoints                             = ["Microsoft.KeyVault", "Microsoft.Storage"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
      delegation = []
    }
    snet-dnsoep = {
      address_prefixes                              = ["172.16.1.16/28", ]
      service_endpoints                             = ["Microsoft.KeyVault", "Microsoft.Storage"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
      delegation = []
    }
    snet-privateEndpoint = {
      address_prefixes                              = ["172.16.1.32/28", ]
      service_endpoints                             = ["Microsoft.KeyVault", "Microsoft.Storage"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
      delegation = []
    }
    AzureFirewallSubnet = {
      address_prefixes                              = ["172.16.1.64/26", ]
      service_endpoints                             = []
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
      delegation = []
    }
    snet-hcsMgmt = {
      address_prefixes                              = ["172.16.1.128/26", ]
      service_endpoints                             = ["Microsoft.KeyVault", "Microsoft.Storage"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
      delegation = []
    }
    AzureBastionSubnet = {
      address_prefixes                              = ["172.16.1.192/26", ]
      service_endpoints                             = ["Microsoft.KeyVault", "Microsoft.Storage"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
      delegation = []
    }
    snet-applicationGateway = {
      address_prefixes                              = ["172.16.0.0/24", ]
      service_endpoints                             = ["Microsoft.KeyVault", "Microsoft.Storage"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
      delegation = []
    }
    snet-hcs001 = {
      address_prefixes                              = ["172.16.2.0/27", ]
      service_endpoints                             = ["Microsoft.KeyVault", "Microsoft.Storage"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
      ingress_internal_loadbalancer_ip              = "172.16.2.8"
      delegation = []
    }
  }
  peerings = []
}
