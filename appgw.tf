resource "azurerm_network_security_group" "ag_subnet_nsg" {
  name                  = "${module.vnet-hcs.subnets["snet-applicationGateway"].name}-nsg-${var.location}"
  location              = var.location
  resource_group_name   = module.rg_hcs.name
  tags                  = merge(local.hcs_tags, {})
}

# Associate NSG and Subnet
resource "azurerm_subnet_network_security_group_association" "ag_subnet_nsg_associate" {
  depends_on                = [ azurerm_network_security_rule.ag_nsg_rule_inbound]
  subnet_id                 = module.vnet-hcs.subnets["snet-applicationGateway"].subnet_ids
  network_security_group_id = azurerm_network_security_group.ag_subnet_nsg.id
}

# Create NSG Rules
## Locals Block for Security Rules
locals {
  ag_inbound_ports_map = {
    "100" : "80",
    "110" : "443",
    "130" : "65200-65535"
  }
}
## NSG Inbound Rule for Azure Application Gateway Subnets
resource "azurerm_network_security_rule" "ag_nsg_rule_inbound" {
  for_each = local.ag_inbound_ports_map
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
  network_security_group_name = azurerm_network_security_group.ag_subnet_nsg.name
}

# Azure Application Gateway Firewall Policy
resource "azurerm_web_application_firewall_policy" "web_ag_waf_policy" {
  name                  = "hcs-web-ag-waf-policy-${var.location}"
  location              = var.location
  resource_group_name   = module.rg_hcs.name
  tags                  = merge(local.hcs_tags, {})

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 768
  }

  #custom_rules {
  #  name      = "Rule1"
  #  priority  = 1
  #  rule_type = "MatchRule"

  #  match_conditions {
  #    match_variables {
  #      variable_name = "RemoteAddr"
  #    }

  #    operator           = "IPMatch"
  #    negation_condition = false
  #    match_values       = ["192.168.1.0/24"]
  #  }

  #  match_conditions {
  #    match_variables {
  #      variable_name = "RequestHeaders"
  #      selector      = "UserAgent"
  #    }

  #    operator           = "Contains"
  #    negation_condition = false
  #    match_values       = ["Windows"]
  #  }

  #  action = "Block"
  #}
}

# Azure Application Gateway Public IP
resource "azurerm_public_ip" "web_ag_publicip" {
  name                        = "hcs-web-ag-publicip-${var.location}"
  location                    = var.location
  resource_group_name         = module.rg_hcs.name
  allocation_method           = "Static"
  sku                         = "Standard"
  zones                       = var.zones
  tags                        = merge(local.hcs_tags, {})
}

# Azure Application Gateway
resource "azurerm_application_gateway" "web_ag" {
  name                              = "hcs-web-ag-${var.location}"
  location                          = var.location
  resource_group_name               = module.rg_hcs.name
  zones                             = var.zones
  tags                              = merge(local.hcs_tags, {})
  firewall_policy_id                = azurerm_web_application_firewall_policy.web_ag_waf_policy.id
  force_firewall_policy_association = true
  sku {
    name     = var.appgw_sku
    tier     = var.appgw_sku
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "hcs-${var.location}-web-ag-ip-configuration"
    subnet_id = module.vnet-hcs.subnets["snet-applicationGateway"].subnet_ids
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.agw_identity.id]
  }

  # Frontend Port  - HTTP Port 80
  frontend_port {
    name = local.frontend_port_name_http
    port = 80
  }

  # Frontend Port  - HTTP Port 443
  frontend_port {
    name = local.frontend_port_name_https
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.web_ag_publicip.id
  }

  # HTTP Listener - Port 80
  http_listener {
    name                           = local.listener_name_http
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name_http
    protocol                       = "Http"
  }

  # HTTP Routing Rule - HTTP to HTTPS Redirect
  request_routing_rule {
    name                         = local.request_routing_rule_name_http
    rule_type                    = "Basic"
    http_listener_name           = local.listener_name_http
    redirect_configuration_name  = local.redirect_configuration_name
    priority                     = 101
  }

  # HTTPS Routing Rule - Port 443
  request_routing_rule {
    name                       = local.request_routing_rule_name_https
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name_https
    backend_address_pool_name  = local.backend_address_pool_name_app1
    backend_http_settings_name = local.http_setting_name_app1
    priority                   = 100
  }

  # Redirect Config for HTTP to HTTPS Redirect
  redirect_configuration {
    name                       = local.redirect_configuration_name
    redirect_type              = "Permanent"
    target_listener_name       = local.listener_name_https
    include_path               = true
    include_query_string       = true
  }

  # HTTPS Listener - Port 443
  http_listener {
    name                           = local.listener_name_https
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name_https
    protocol                       = "Https"
    ssl_certificate_name           = local.ssl_certificate_name
  }

  # App1 Configs
  backend_address_pool {
    name         = local.backend_address_pool_name_app1
    ip_addresses = [local.internal_load_balancer_ip_address]
  }

  backend_http_settings {
    name                           = local.http_setting_name_app1
    cookie_based_affinity          = "Disabled"
    #path                           = "/app1/"
    port                           = 443
    protocol                       = "Https"
    request_timeout                = 60
    probe_name                     = local.probe_name_app1
    trusted_root_certificate_names = ["hcs-aks-backend-cert"]
  }

  probe {
    name                = local.probe_name_app1
    host                = var.k8s_doamin_name
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 8
    protocol            = "Https"
    path                = "/healthz"
    match {
      status_code       = ["200-399", "404"]
    }
  }

  trusted_root_certificate {
    name                = "hcs-aks-backend-cert"
    key_vault_secret_id = azurerm_key_vault_certificate.hcs_aks_backend_cert.secret_id
    #key_vault_secret_id = azurerm_key_vault_certificate.hcs_aks_backend_cert.versionless_secret_id
   }

  # SSL Certificate Block
  ssl_certificate {
    name = local.ssl_certificate_name
    password = "Avaya123!"
    data = filebase64("${path.module}/ssl-self-signed/${var.appgw_frontend_cert_name}-${var.location}.pfx")
  }

  #ssl_certificate {
  #  name = local.ssl_certificate_name_keyvault
  #  key_vault_secret_id = azurerm_key_vault_certificate.hcs_aks_backend_cert.secret_id
  #}
}
