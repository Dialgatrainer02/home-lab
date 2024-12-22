resource "proxmox_virtual_environment_container" "proxmox_ct" {

  description = var.description

  started   = true
  node_name = local.node
  vm_id     = var.vm_id

  unprivileged = true

  initialization {
    hostname = var.hostname

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
    }
  }
  cpu {
    cores = var.cores
  }

  disk {
    datastore_id = local.datastore_id
    size         = var.disk_size
  }
  memory {
    dedicated = var.mem_size
    swap      = var.swap_size
  }

  network_interface {
    name = "veth0"
  }

  operating_system {
    template_file_id = var.os_image
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type = "centos"
  }
  start_on_boot = "true"

  connection {
    host     = var.pve_address
    type     = "ssh"
    user     = local.pve_user
    password = var.pve_password
  }

  provisioner "file" {
    source      = "${path.module}/enable_ssh.sh"
    destination = "/mnt/bindmounts/terraform/enable_ssh.sh"

  }

  provisioner "remote-exec" {
    inline = [
      "pct exec ${var.vm_id} bash /terraform/enable_ssh.sh"
    ]
  }
  mount_point {
    volume = "/mnt/bindmounts/terraform"
    path   = "/terraform"
    shared = "true"
  }
}
