resource "azurerm_public_ip" "bastion_service_publicip" {
  name                = "hcs-bastion-service-publicip-${var.location}"
  location            = var.location
  resource_group_name = module.rg_hcs.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(local.hcs_tags, {})
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = "hcs-bastion-service-${var.location}"
  location            = var.location
  resource_group_name = module.rg_hcs.name
  tags                = merge(local.hcs_tags, {})

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.vnet-hcs.subnets["AzureBastionSubnet"].subnet_ids
    public_ip_address_id = azurerm_public_ip.bastion_service_publicip.id
  }
}
