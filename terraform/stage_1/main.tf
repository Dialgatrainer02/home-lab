module "dns" {
  source = "../modules/proxmox_ct"


  vm_id        = 200
  hostname     = "dns"
  description  = "dns server"
  ipv4_address = "${var.ipv4_subnet_net}.200${var.ipv4_subnet_cidr}"
  ipv4_gw      = var.ipv4_gw
  dns          = ["1.1.1.1", ]
  public_key   = var.public_key
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = var.ct_image
  host_vars = {
    acme_cert_name = "${module.dns.hostname}.${var.domain}"
    acme_cert_san  = [module.dns.ct_ipv4_address]
  }

  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}

module "configure_dns" {
  source     = "../modules/playbook"
  depends_on = [module.dns]

  playbook          = "../ansible/dns-playbook.yml" # from root not module
  host_key_checking = "false"
  private_key_file  = var.private_key_path
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    custom_dns = merge({
      "${local.dns_names.ca}"    = module.step_ca.ct_ipv4_address
      "${local.dns_names.dns}"   = module.dns.ct_ipv4_address
      "${local.dns_names.wg_gw}" = module.wg_gw.ct_ipv4_address
    }, var.extra_dns)
  }
  inventory = local.dns
}


module "step_ca" {
  source = "../modules/proxmox_ct"


  vm_id        = 201
  hostname     = "step-ca"
  description  = "Step ca server"
  ipv4_address = "${var.ipv4_subnet_net}.201${var.ipv4_subnet_cidr}"
  ipv4_gw      = var.ipv4_gw
  dns          = [module.dns.ct_ipv4_address]
  public_key   = var.public_key
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = var.ct_image
  host_vars = {
    acme_cert_name = "${local.dns_names.ca}"
    acme_cert_san  = [module.step_ca.ct_ipv4_address]
  }

  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}


module "configure_step_ca" {
  source     = "../modules/playbook"
  depends_on = [module.step_ca]

  playbook          = "../ansible/ca-playbook.yml"
  host_key_checking = "false"
  private_key_file  = var.private_key_path
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    ca_name     = "staging-homelab"
    ca_password = var.pve_password
    ca_ssh      = false
  }
  inventory = local.ca
}

# module "wg_vps" {
# source = "../modules/oci_vm"
# 
# 
# tenancy_ocid     = var.tenancy_ocid
# compartment_ocid = var.compartment_ocid
# region           = var.region
# user_ocid        = var.user_ocid
# fingerprint      = var.fingerprint
# oci_private_key  = var.oci_private_key
# public_key       = var.public_key
# private_key      = var.private_key
# 
# vcn_ip_range    = "10.0.0.0/16"
# vcn_label       = "wg_vcn"
# dhcp_dns        = ["1.1.1.1", "1.0.0.1"]
# subnet_ip_range = "10.99.0.1/24"
# subnet_label    = "wg_subnet"
# gw_label        = "wg_gw"
# security_label  = "wg_security"
# ingress_rules = [{ # wireguard and ssh
# protocol    = "17"
# source      = "0.0.0.0/0"
# udp_options = { min = 51820, max = 51820 }
# },
# {
# protocol    = "6"
# source      = "0.0.0.0/0"
# tcp_options = { min = 22, max = 22 }
# }]
# instance_label = "wireguard_instance"
# hostname       = "wireguard_oci"
# host_vars = {
# wireguard_allowed_ips          = "192.168.0.0/24"
# wireguard_addresses            = ["10.51.0.2/24"]
# wireguard_persistent_keepalive = "30"
# }
# 
# }

module "wg_gw" {
  source = "../modules/proxmox_ct"


  vm_id        = 202
  hostname     = "wg-gw"
  description  = "Wireguard gateway to access vps"
  ipv4_address = "${var.ipv4_subnet_net}.202${var.ipv4_subnet_cidr}"
  ipv4_gw      = var.ipv4_gw
  dns          = [module.dns.ct_ipv4_address]
  public_key   = var.public_key
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = var.ct_image
  host_vars = {
    wireguard_allowed_ips          = "192.168.0.0/24"
    wireguard_addresses            = ["10.51.0.2/24"]
    wireguard_persistent_keepalive = "30"
  }
  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}

# module "wireguard" {
# source = "../modules/playbook"
# depends_on = [module.wg_gw,
# module.wg_vps]
# 
# playbook         = "../ansible/wg-playbook.yml"
# inventory        = local.wireguard
# private_key_file = var.private_key_path
# }

module "acme_certs" {
  source = "../modules/playbook"
  depends_on = [
    module.configure_dns,     # requires dns names
    module.configure_step_ca, # requires working ca
  ]

  playbook          = "../ansible/cert-playbook.yml"
  host_key_checking = "false"
  private_key_file  = var.private_key_path
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    ca_url = "https://${module.step_ca.ct_ipv4_address}"
  }
  inventory = merge(local.dns, local.ca, ) # local.wireguard
}