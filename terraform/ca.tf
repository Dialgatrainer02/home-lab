module "ca-1" {
  source = "${path.root}/modules/proxmox_ct"


  vm_id        = 200
  hostname     = "ca-1"
  description  = "Step ca server"
  ipv4_address = "${var.ipv4_subnet_pre}.200${var.ipv4_subnet_cidr}"
  ipv4_gw      = "192.168.0.1"
  dns          = ["${trimsuffix(module.dns-1.ct_ipv4_address, "/24")}"]
  public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
  host_vars = {
    acme_cert_name = "ca-1.dialgatrainer.duckdns.org"
    acme_cert_san  = ["${trimsuffix(module.ca-1.ct_ipv4_address, var.ipv4_subnet_cidr)}"]
  }
  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}
