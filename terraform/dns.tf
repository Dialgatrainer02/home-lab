module "dns-1" {
  source       = "${path.root}/modules/proxmox_ct"
  vm_id        = 201
  hostname     = "dns-1"
  description  = "dns  server"
  ipv4_address = "${var.ipv4_subnet_pre}.201${var.ipv4_subnet_cidr}"
  ipv4_gw      = "192.168.0.1"
  dns          = ["1.1.1.1", "1.0.0.1"]
  public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
  host_vars = {
    acme_cert_name = "dns-1.dialgatrainer.duckdns.org"
    acme_cert_san  = [module.dns-1.ct_ipv4_address]
  }
  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}
