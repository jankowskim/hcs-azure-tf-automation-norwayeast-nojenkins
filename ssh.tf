resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

resource "azapi_resource" "ssh_public_key" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name        = "hcs-ssh-key-${var.location}"
  location    = var.location
  parent_id   = module.rg_hcs.id
  tags        = merge(local.hcs_tags, {})
}

# Keyvault Creation
resource "azurerm_key_vault" "hcs_keyvault" {
  name                        = "hcs-keyvault-${var.location}"
  location                    = var.location
  resource_group_name         = module.rg_hcs.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = merge(local.hcs_tags, {})

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "Get",
    ]
    secret_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set",
    ]
    storage_permissions = [
      "Get",
    ]
  }
}

#
resource "azurerm_key_vault_secret" "hcs_keyvault_secret" {
  name         = "hcs-mgmt-ssh-key-${var.location}"
  value        = jsondecode(azapi_resource_action.ssh_public_key_gen.output).privateKey
  key_vault_id = azurerm_key_vault.hcs_keyvault.id
  depends_on   = [ azurerm_key_vault.hcs_keyvault ]
  tags         = merge(local.hcs_tags, {})
}

output "key_data" {
  value = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
}

output "private_key" {
  value = jsondecode(azapi_resource_action.ssh_public_key_gen.output).privateKey
}
