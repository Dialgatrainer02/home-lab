# module "minio" {
#   source = "${path.root}/modules/proxmox_ct"


#   vm_id        = 203
#   hostname     = "minio"
#   description  = "s3 compatible block storage"
#   ipv4_address = "${var.ipv4_subnet_pre}.203${var.ipv4_subnet_cidr}"
#   ipv4_gw      = "192.168.0.1"
#   dns          = [module.dns-1.ct_ipv4_address]
#   public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
#   cores        = 1
#   disk_size    = "10"
#   mem_size     = "1024"
#   os_image     = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
#   host_vars = {
#     acme_cert_name = "${local.dns_names.minio}"
#     acme_cert_san  = [module.minio.ct_ipv4_address]
#   }

#   pve_address  = var.pve_address
#   pve_password = var.pve_password
#   pve_username = var.pve_username
# }

# module "mimir" {
#   source = "${path.root}/modules/proxmox_ct"


#   vm_id        = 204
#   hostname     = "mimir"
#   description  = "grafana mimir "
#   ipv4_address = "${var.ipv4_subnet_pre}.204${var.ipv4_subnet_cidr}"
#   ipv4_gw      = "192.168.0.1"
#   dns          = [module.dns-1.ct_ipv4_address]
#   public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
#   cores        = 1
#   disk_size    = "10"
#   mem_size     = "1024"
#   os_image     = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
#   host_vars = {
#     acme_cert_name = "${local.dns_names.mimir}"
#     acme_cert_san  = [module.mimir.ct_ipv4_address]
#   }

#   pve_address  = var.pve_address
#   pve_password = var.pve_password
#   pve_username = var.pve_username
# }