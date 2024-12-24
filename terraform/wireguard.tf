module "wg_vps" {
  source = "./modules/oci_vm"

  tenancy_ocid     = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
  region           = var.region
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  oci_private_key  = var.oci_private_key
  public_key       = tls_private_key.staging_key.public_key_openssh
  private_key      = tls_private_key.staging_key.private_key_openssh

  vcn_ip_range    = "10.0.0.0/16"
  vcn_label       = "wg_vcn"
  dhcp_dns        = ["1.1.1.1", "1.0.0.1"]
  subnet_ip_range = "10.99.0.1/24"
  subnet_label    = "wg_subnet"
  gw_label        = "wg_gw"
  security_label  = "wg_security"
  # ingress_rules = [{ # wireguard and ssh
  # protocol = "17"
  # source   = "0.0.0.0/0"
  # udp_options = { min = 51820, max = 51820 }
  # },
  # {
  # protocol    = "6"
  # source      = "0.0.0.0/0"
  # tcp_options = { min = 22, max = 22 }
  # }]
  instance_label = "wireguard_instance"
  hostname       = "wireguard_oci"
  host_vars = {
    wireguard_allowed_ips          = "192.168.0.0/24"
    wireguard_addresses            = ["10.51.0.2/24"]
    wireguard_persistent_keepalive = "30"
  }

}


# wireguard gateway for lan

module "wg_gw" {
  source = "${path.root}/modules/proxmox_ct"
  # depends_on = [ module.configure_dns ]


  vm_id        = 202
  hostname     = "wg-gw"
  description  = "Wireguard gateway to access vps"
  ipv4_address = "${var.ipv4_subnet_pre}.202${var.ipv4_subnet_cidr}"
  ipv4_gw      = "192.168.0.1"
  dns          = ["${trimsuffix(module.dns-1.ct_ipv4_address, "/24")}"]
  public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
  host_vars = {
    wireguard_allowed_ips          = "192.168.0.0/24"
    wireguard_addresses            = ["10.51.0.2/24"]
    wireguard_persistent_keepalive = "30"
  }
  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}



module "wireguard" {
  source = "./modules/playbook"

  playbook = "../ansible/wg-playbook.yml"
  inventory = {
    wireguard = {
      hosts = merge(module.wg_gw.host, module.wg_vps.host)
    }
  }
  private_key_file = "./private_staging_key"
}