terraform {
  required_version = "1.8.8"
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.69.0"
    }
    oci = {
      source = "hashicorp/oci"
      version = "6.21.0"
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
