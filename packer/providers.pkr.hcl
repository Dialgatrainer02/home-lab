packer {
  required_plugins {
    name = {
      version = "1.2.1" # pinned due to cpu_type not being paassed
      source  = "github.com/hashicorp/proxmox"
    }
  }
}
