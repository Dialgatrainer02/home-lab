terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    local = {
      source = "hashicorp/local"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}