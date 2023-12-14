# Create NSG Rules
locals {
  hcs_mgmt_nic_inbound_ports_map = {
    "100" : "80",
    "110" : "443",
    "120" : "22"
  }
}

resource "azurerm_network_security_group" "hcs_mgmt_nsg" {
  name                = "${azurerm_network_interface.hcs_mgmt_nic.name}-nsg-${var.location}"
  location            = var.location
  resource_group_name = module.rg_hcs.name
  tags                = merge(local.hcs_tags, {})
}

resource "azurerm_network_interface_security_group_association" "hcs_mgmt_nsg_associate" {
  depends_on = [ azurerm_network_security_rule.hcs_mgmt_nsg_rule_inbound]
  network_interface_id      = azurerm_network_interface.hcs_mgmt_nic.id
  network_security_group_id = azurerm_network_security_group.hcs_mgmt_nsg.id
}

resource "azurerm_network_security_rule" "hcs_mgmt_nsg_rule_inbound" {
  for_each = local.hcs_mgmt_nic_inbound_ports_map
  name                        = "Rule-Port-${each.value}"
  priority                    = each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = module.rg_hcs.name
  network_security_group_name = azurerm_network_security_group.hcs_mgmt_nsg.name
}

resource "azurerm_network_interface" "hcs_mgmt_nic" {
  name                = "hcs-mgmt-nic-${var.location}"
  location            = var.location
  resource_group_name = module.rg_hcs.name
  tags                = merge(local.hcs_tags, {})

  ip_configuration {
    name                          = "hcs_nic_configuration"
    subnet_id                     = module.vnet-hcs.subnets["snet-hcsMgmt"].subnet_ids
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_id" "random_id" {
  keepers = {
    resource_group = module.rg_hcs.name
  }

  byte_length = 8
}

resource "azurerm_storage_account" "hcs_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = var.location
  resource_group_name      = module.rg_hcs.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = merge(local.hcs_tags, {})
}

resource "azurerm_linux_virtual_machine" "hcs_mgmt_vm" {
  name                  = "hcs-mgmt-vm-${var.location}"
  location              = var.location
  resource_group_name   = module.rg_hcs.name
  network_interface_ids = [azurerm_network_interface.hcs_mgmt_nic.id]
  size                  = "Standard_DS1_v2"
  tags                  = merge(local.hcs_tags, {})
  depends_on            = [azurerm_kubernetes_cluster.hcs_k8s]

  os_disk {
    name                 = "hcs_mgmt_vm_OsDisk_${var.location}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  computer_name  = "hcs-mgmt-vm-${var.location}"
  admin_username = var.k8s_admin_username
  #admin_password = "brixbrix123!"
  #disable_password_authentication = false

  admin_ssh_key {
    username   = var.k8s_admin_username
    public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.hcs_storage_account.primary_blob_endpoint
  }

}

resource "local_file" "ingress_yaml_file_template" {
  content = templatefile("${path.module}/manifest/ingress-controller_internal.tpl",
    {
      ingress_internal_loadbalancer_ip = cidrhost((join(", ", module.vnet-hcs.subnets["snet-hcs001"].address_prefixes)), 8)
    })
  filename = "${path.module}/manifest/ingress-controller_internal.yaml"
}

data "azurerm_key_vault_certificate_data" "hcs_aks_backend_cert" {
  name         = "hcs-aks-backend-cert-${var.location}"
  key_vault_id = azurerm_key_vault.hcs_keyvault.id
  depends_on   = [azurerm_key_vault_certificate.hcs_aks_backend_cert]
}

data "local_file" "ingress_yaml_file" {
  filename = "${path.module}/manifest/ingress-controller_internal.yaml"
  depends_on = [local_file.ingress_yaml_file_template]
}

resource "azurerm_virtual_machine_extension" "hcs_mgmt_setup_script" {
  name                      = "hcs-mgmt-setup-script-${var.location}"
  virtual_machine_id        = azurerm_linux_virtual_machine.hcs_mgmt_vm.id
  publisher                 = "Microsoft.Azure.Extensions"
  type                      = "CustomScript"
  type_handler_version      = "2.0"

  settings = <<SETTINGS
  {
    "script": "${base64encode(templatefile("${path.module}/scripts/setup-mgmt-node.sh", {
    kube_config="${azurerm_kubernetes_cluster.hcs_k8s.kube_config_raw}",
    k8s_cluster_name="${azurerm_kubernetes_cluster.hcs_k8s.name}",
    k8s_admin_username="${var.k8s_admin_username}",
    k8s_doamin_name="${var.k8s_doamin_name}",
    ingress_yaml_file="${data.local_file.ingress_yaml_file.content}",
    hcs_aks_backend_cert_pem="${data.azurerm_key_vault_certificate_data.hcs_aks_backend_cert.pem}",
    hcs_aks_backend_cert_key="${data.azurerm_key_vault_certificate_data.hcs_aks_backend_cert.key}",
    bash_profile="/home/${var.k8s_admin_username}/.bash_profile",
    bash_aliases="/home/${var.k8s_admin_username}/.bash_aliases"
    switcher_version="${var.switcher_version}",
    k9s_version="${var.k9s_version}",
    aws_region="${var.aws_region}",
    aws_access_key_id="${var.aws_access_key_id}",
    aws_secret_access_key="${var.aws_secret_access_key}",
    git_repos=join(",", var.git_repos),
    }))}"
  }
  SETTINGS

  depends_on = [ azurerm_linux_virtual_machine.hcs_mgmt_vm, local_file.ingress_yaml_file_template]
}
