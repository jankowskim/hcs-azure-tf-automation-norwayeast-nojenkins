resource "azurerm_network_security_group" "ag_subnet_nsg" {
  name                  = "${module.vnet-hcs.subnets["snet-applicationGateway"].name}-nsg-${var.location}"
  location              = var.location
  resource_group_name   = module.rg_hcs.name
  tags                  = merge(local.hcs_tags, {})
}

# Associate NSG and Subnet
resource "azurerm_subnet_network_security_group_association" "ag_subnet_nsg_associate" {
  depends_on = [ azurerm_network_security_rule.ag_nsg_rule_inbound]
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

# Azure Application Gateway - Standard
resource "azurerm_application_gateway" "web_ag" {
  name                        = "hcs-web-ag-${var.location}"
  location                    = var.location
  resource_group_name         = module.rg_hcs.name
  zones                       = var.zones
  tags                        = merge(local.hcs_tags, {})
  sku {
    name     = var.appgw_sku
    tier     = var.appgw_sku
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "hcs-${var.location}-web-ag-ip-configuration"
    subnet_id = module.vnet-hcs.subnets["snet-applicationGateway"].subnet_ids
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
    name                       = local.request_routing_rule_name_http
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name_http
    redirect_configuration_name = local.redirect_configuration_name
    priority                   = 101
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
    name = local.redirect_configuration_name
    redirect_type = "Permanent"
    target_listener_name = local.listener_name_https
    include_path = true
    include_query_string = true
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
    name = local.backend_address_pool_name_app1
  }

  backend_http_settings {
    name                  = local.http_setting_name_app1
    cookie_based_affinity = "Disabled"
    #path                  = "/app1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = local.probe_name_app1
  }

  probe {
    name                = local.probe_name_app1
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/app1/status.html"
    match { # Optional
      body              = "App1"
      status_code       = ["200"]
    }
  }

  # SSL Certificate Block
  ssl_certificate {
    name = local.ssl_certificate_name
    password = "Avaya123!"
    data = filebase64("${path.module}/ssl-self-signed/${var.appgw_frontend_cert_name}-${var.location}.pfx")
  }

  # WAF Config
  waf_configuration {
   firewall_mode            = "Prevention"
   rule_set_type            = "OWASP"
   rule_set_version         = "3.2"
   enabled                  = true
   max_request_body_size_kb = "128"
   file_upload_limit_mb     = "750"
  }
}
