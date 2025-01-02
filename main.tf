module "test" {
  source = "./modules/prmoxmox/container"

  container = {
    os_image    = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
    os_type     = "centos"
    gen_keypair = true

  }
  pve_address  = var.pve_address
  pve_username = var.pve_username
  pve_password = var.pve_password
}

resource "proxmox_virtual_environment_download_file" "release_almalinux_9-4_lxc_img" {
  connection { # kinda hacky way to make the directory
    host     = var.pve_address
    type     = "ssh"
    user     = local.pve_user
    password = var.pve_password
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /mnt/bindmounts/terraform"
    ]
  }
  overwrite_unmanaged = true
  content_type        = "vztmpl"
  datastore_id        = "local"
  node_name           = local.node
  url                 = "http://download.proxmox.com/images/system/almalinux-9-default_20240911_amd64.tar.xz"
}

output "testing" {
  value = module.test.ipv4_address

}

output "test_private_key" {
  value     = module.test.private_key
  sensitive = true
}