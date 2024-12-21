terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
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
  compartment_ocid = var.compartment_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key      = var.private_key
}


