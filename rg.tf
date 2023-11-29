module "rg_hcs" {
  source  = "app.terraform.io/AvayaCloud/aocp-core-infra-resourcegroup/azurerm"
  version = "0.0.1"

  location = var.location
  name     = "rg-hcs-${var.location}-${var.env}"
  tags     = merge(local.hcs_tags, {})
}
