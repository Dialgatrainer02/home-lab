terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    oci = {
      source = "hashicorp/oci"
    }
    local = {
      source = "hashicorp/local"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${var.pve_address}:8006"

  username = var.pve_username
  password = var.pve_password
  insecure = true
  tmp_dir  = "/tmp"
}

provider "oci" {
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}


# TODO how to move into module without redownloading every time
resource "proxmox_virtual_environment_download_file" "release_almalinux_9-4_lxc_img" {
  connection {
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

resource "tls_private_key" "staging_key" {
  algorithm = "ED25519"

}

module "Step_ca" {
  source       = "./proxmox_ct"
  vm_id        = 200
  hostname     = "step-ca"
  description  = "Step ca server"
  ipv4_address = "${var.ipv4_subnet_pre}.200${var.ipv4_subnet_cidr}"
  ipv4_gw      = "192.168.0.1"
  dns          = ["1.1.1.1", "1.0.0.1"]
  public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}

