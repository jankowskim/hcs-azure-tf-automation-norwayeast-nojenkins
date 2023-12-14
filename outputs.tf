output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.hcs_k8s.name
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.hcs_k8s.kube_config[0].client_certificate
  sensitive = true
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.hcs_k8s.kube_config[0].client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.hcs_k8s.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "cluster_password" {
  value     = azurerm_kubernetes_cluster.hcs_k8s.kube_config[0].password
  sensitive = true
}

output "cluster_username" {
  value     = azurerm_kubernetes_cluster.hcs_k8s.kube_config[0].username
  sensitive = true
}

output "host" {
  value     = azurerm_kubernetes_cluster.hcs_k8s.kube_config[0].host
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.hcs_k8s.kube_config_raw
  sensitive = true
}

output "ingress_internal_loadbalancer_ip" {
  value     = cidrhost((join(", ", module.vnet-hcs.subnets["snet-hcs001"].address_prefixes)), 8)
}

output "hcs_mgmtvm_network_interface_id" {
  description = "HCS MGMT VM Network Interface ID"
  value = azurerm_network_interface.hcs_mgmt_nic.id
}

output "hcs_mgmtvm_network_interface_private_ip_addresses" {
  description = "HCS MGMT VM Private IP Addresses"
  value = [azurerm_network_interface.hcs_mgmt_nic.private_ip_address]
}

# MGTM VM Outputs
output "hcs_mgmtvm_private_ip_address" {
  description = "HCS MGMT VM Virtual Machine Private IP"
  value = azurerm_linux_virtual_machine.hcs_mgmt_vm.private_ip_address
}

output "hcs_mgmtvm_virtual_machine_id_128bit" {
  description = "HCS MGMT VM Virtual Machine ID - 128-bit identifier"
  value = azurerm_linux_virtual_machine.hcs_mgmt_vm.virtual_machine_id
}

output "hcs_mgmtvm_virtual_machine_id" {
  description = "HCS MGMT VM Virtual Machine ID "
  value = azurerm_linux_virtual_machine.hcs_mgmt_vm.id
}

## Bastion Host Public IP Output
#output "bastion_host_public_ip_address" {
#  description = "Bastion Host Public Address"
#  value = azurerm_public_ip.bastion_service_publicip.ip_address
#}
