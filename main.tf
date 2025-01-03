locals {
  pve_settings = {
    pve_address  = var.pve_address
    pve_password = var.pve_password
    pve_username = var.pve_username
  }
}
resource "proxmox_virtual_environment_download_file" "release_almalinux_9_4_lxc_img" {
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

module "dns" {
  source = "./modules/service_ct"

  pve_settings = local.pve_settings
  service = {
    service_name        = "dns-1"
    service_type        = "dns"
    service_description = "dns server 1"
    service_os_image    = proxmox_virtual_environment_download_file.release_almalinux_9_4_lxc_img.id
    service_os_type     = "centos"
    service_ipv4 = {
      ipv4_address = "${var.ipv4_network_bits}.201${var.ipv4_cidr}"
      ipv4_gateway = var.ipv4_gateway
    }
    custom_ct = {
      startup = true
      cores   = 1
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
  service_vars = {
    dnsmasq_domain = "internal"
  }
}

