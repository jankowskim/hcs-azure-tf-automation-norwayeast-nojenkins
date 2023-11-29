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

  custom_data = filebase64("${path.module}/scripts/setup-mgmt-node.sh")
}
