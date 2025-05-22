terraform {
  required_version = "~>1.9.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.72.0"
    }
    oci = {
      source  = "hashicorp/oci"
      version = "6.21.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.35.1"
    }
    helm = {
      source = "hashicorp/helm"
      version = "3.0.0-pre1"
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

provider "helm" {
  kubernetes = {
  config_path    = "./secrets/.kube/config"
  }
}