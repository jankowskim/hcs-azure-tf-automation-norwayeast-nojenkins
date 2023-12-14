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

    certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "SetIssuers",
      "Update",
    ]

    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey",
    ]

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_user_assigned_identity" "agw_identity" {
  location            = var.location
  resource_group_name = module.rg_hcs.name
  name                = "hcs-agw-msi-${var.location}"
  tags                = merge(local.hcs_tags, {})
}

resource "azurerm_key_vault_access_policy" "agw_keyvault_access_policy" {
  key_vault_id = azurerm_key_vault.hcs_keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.agw_identity.principal_id

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_secret" "hcs_keyvault_secret" {
  name         = "hcs-mgmt-ssh-key-${var.location}"
  value        = jsondecode(azapi_resource_action.ssh_public_key_gen.output).privateKey
  key_vault_id = azurerm_key_vault.hcs_keyvault.id
  depends_on   = [ azurerm_key_vault.hcs_keyvault ]
  tags         = merge(local.hcs_tags, {})
}

resource "azurerm_key_vault_certificate" "hcs_aks_backend_cert" {
  name         = "hcs-aks-backend-cert-${var.location}"
  key_vault_id = azurerm_key_vault.hcs_keyvault.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["hcs001.hcs-prod-1.ec.avayacloud.com"]
      }

      subject            = "CN=hcs001.hcs-prod-1.ec.avayacloud.com"
      validity_in_months = 12
    }
  }
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [azurerm_key_vault_certificate.hcs_aks_backend_cert]

  create_duration = "60s"
}

output "secret_id_of_hcs_aks_backend_cert" {
  value = azurerm_key_vault_certificate.hcs_aks_backend_cert.secret_id
}

output "key_data" {
  value = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
}

output "private_key" {
  value = jsondecode(azapi_resource_action.ssh_public_key_gen.output).privateKey
}
