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
    random = {
      source = "hashicorp/random"
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




resource "tls_private_key" "staging_key" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "private_staging_key" {
  filename = "${path.root}/private_staging_key"
  content  = tls_private_key.staging_key.private_key_openssh
}

module "stage_1" {
  source = "${path.root}/stage_1"

  ipv4_gw          = "192.168.0.1"
  ipv4_subnet_net  = "192.168.0"
  ipv4_subnet_cidr = "/24"
  domain           = local.domain
  extra_dns = merge({
    "pve.${local.domain}"  = "192.168.0.90"
    "pve1.${local.domain}" = "192.168.0.91"
    # find way to add stage 2 dns names nicely
  }, module.stage_2.dns_names)
  public_key       = trimspace(tls_private_key.staging_key.public_key_openssh)
  private_key      = trimspace(tls_private_key.staging_key.private_key_openssh)
  private_key_path = local_sensitive_file.private_staging_key.filename
  ct_image         = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id

  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username

  tenancy_ocid     = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
  region           = var.region
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  oci_private_key  = var.oci_private_key
}

module "stage_2" {
  source = "${path.root}/stage_2"

  ipv4_gw          = "192.168.0.1"
  ipv4_subnet_net  = "192.168.0"
  ipv4_subnet_cidr = "/24"
  domain           = local.domain
  alloy_hosts      = module.stage_1.inventory #find way to add alloy to existing hosts nicely + dns names 
  public_key       = trimspace(tls_private_key.staging_key.public_key_openssh)
  private_key      = trimspace(tls_private_key.staging_key.private_key_openssh)
  private_key_path = local_sensitive_file.private_staging_key.filename
  ct_image         = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id

  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username

}