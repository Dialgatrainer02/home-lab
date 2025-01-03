module "testing_more" {
  source = "./modules/service_ct"

  pve_settings = {
    pve_address  = var.pve_address
    pve_password = var.pve_password
    pve_username = var.pve_password
  }
  service = {
    service_name        = "dns-1"
    service_type        = "dns"
    service_description = "dns server 1"
    service_ipv4 = {
      address = "${var.ipv4_network_bits}.200${var.ipv4_cidr}"
      gateway = var.ipv4_gateway
    }
    custom_ct = {
      startup = false
    }
  }
  alloy = {
    install = false
  }
  consul = {
    install = false
  }
  dns = {
    entry = false
  }
}
