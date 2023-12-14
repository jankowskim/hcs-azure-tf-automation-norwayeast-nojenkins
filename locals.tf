locals {
  hcs_tags = {
    "location"    = lower(var.location)
    "environment" = lower(var.env)
    "customer"    = lower(var.deployment_id)
    "offer_code"  = lower(var.offer_code)
  }

  # Azure Application Gateway
  frontend_ip_configuration_name      = "${module.vnet-hcs.vnet_name}-feip"
  redirect_configuration_name         = "${module.vnet-hcs.vnet_name}-rdrcfg"

  # App1
  backend_address_pool_name_app1      = "${module.vnet-hcs.vnet_name}-beap-app1"
  http_setting_name_app1              = "${module.vnet-hcs.vnet_name}-be-htst-app1"
  probe_name_app1                     = "${module.vnet-hcs.vnet_name}-be-probe-app1"

  # HTTP Listener -  Port 80
  listener_name_http                  = "${module.vnet-hcs.vnet_name}-lstn-http"
  request_routing_rule_name_http      = "${module.vnet-hcs.vnet_name}-rqrt-http"
  frontend_port_name_http             = "${module.vnet-hcs.vnet_name}-feport-http"

  # HTTPS Listener -  Port 443
  listener_name_https                 = "${module.vnet-hcs.vnet_name}-lstn-https"
  request_routing_rule_name_https     = "${module.vnet-hcs.vnet_name}-rqrt-https"
  frontend_port_name_https            = "${module.vnet-hcs.vnet_name}-feport-https"
  ssl_certificate_name                = "hcs-${var.location}-front-end-cert"
  ssl_certificate_name_keyvault       = "hcs-${var.location}-back-end-cert"

  internal_load_balancer_ip_address   = cidrhost((join(", ", module.vnet-hcs.subnets["snet-hcs001"].address_prefixes)), 8)
}
