resource "proxmox_virtual_environment_vm" "almalinux_vm" {

  name        = var.name
  node_name   = local.node
  vm_id       = var.vm_id
  description = var.description

  started = "true"
  on_boot = "true"
  bios    = "ovmf"
  machine = "q35"


  agent {
    enabled = var.agent
  }
  stop_on_destroy = true

  initialization {
    datastore_id = local.datastore_id
    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gw
      }
    }
    dns {
      servers = var.dns
    }


    user_account {
      keys = [
        var.public_key
      ]
      username = var.username
    }
  }

  cpu {
    type  = "host"
    cores = var.cores
  }
  memory {
    dedicated = var.mem_size
  }

  disk {
    datastore_id = local.datastore_id
    file_id      = var.os_image
    file_format  = var.os_image_type
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.disk_size
  }

  efi_disk {
    datastore_id = local.datastore_id
    file_format  = "raw"
    type         = "4m"
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }
}