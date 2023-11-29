module "vnet-hcs" {
  source  = "app.terraform.io/AvayaCloud/aocp-core-infra-vnethub/azurerm"
  version = "0.0.9"
  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm
  }

  vnet_name                  = "vnet-hcs-${var.location}"
  location                   = var.location
  resource_group_name        = module.rg_hcs.name
  address_spaces             = var.vnet_hcs.address_spaces
  dns_servers                = []
  subnets                    = var.vnet_hcs.subnets
  peerings                   = var.vnet_hcs.peerings
  tags                       = merge(local.hcs_tags, {})
  ddos_protection_plan_id    = ""
}
