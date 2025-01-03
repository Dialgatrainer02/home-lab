resource "proxmox_virtual_environment_download_file" "release_almalinux_9_4_lxc_img" {
  connection { # kinda hacky way to make the directory
    host     = var.pve_settings.pve_address
    type     = "ssh"
    user     = local.pve_user
    password = var.pve_settings.pve_password
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
module "service_ct" {
  source = "../prmoxmox/container"

  container = merge({
    hostname    = var.service.service_name
    description = var.service.service_description
    os_image    = proxmox_virtual_environment_download_file.release_almalinux_9_4_lxc_img.id
    os_type     = "centos"
    host_vars   = var.service.host_vars
  }, var.service.service_ipv4, var.service.custom_ct)
  pve_settings = var.pve_settings

}

