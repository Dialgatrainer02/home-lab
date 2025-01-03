resource "proxmox_virtual_environment_container" "proxmox_ct" {

  description = var.container.description

  started   = true
  node_name = local.node
  vm_id     = local.vm_id

  unprivileged = var.container.unprivileged

  initialization {
    hostname = var.container.hostname

    ip_config {
      ipv4 {
        address = var.container.ipv4_address
        gateway = var.container.ipv4_gateway != null ? var.container.ipv4_gateway : null
      }
    }
    dns {
      servers = var.container.dns
    }

    user_account {
      keys = [
        local.public_key
      ]
    }
  }
  cpu {
    cores = var.container.cores
  }

  disk {
    datastore_id = local.datastore_id
    size         = var.container.disk
  }
  memory {
    dedicated = var.container.memory
    swap      = var.container.swap
  }

  network_interface {
    name = "veth0"
  }

  operating_system {
    template_file_id = var.container.os_image
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type = var.container.os_type
  }
  start_on_boot = var.container.startup

  mount_point {
    volume = "/mnt/bindmounts/terraform"
    path   = "/terraform"
    shared = "true"
  }
}

resource "terraform_data" "provision" {
  depends_on = [proxmox_virtual_environment_container.proxmox_ct]
  connection {
    host     = var.pve_settings.pve_address
    type     = "ssh"
    user     = local.pve_user
    password = var.pve_settings.pve_password
  }

  provisioner "file" {
    source      = "${path.module}/enable_ssh.sh"
    destination = "/mnt/bindmounts/terraform/enable_ssh.sh"

  }
  provisioner "remote-exec" {
    inline = [
      "pct exec ${local.vm_id} bash /terraform/enable_ssh.sh" # vmid goes in space
    ]
  }
}

resource "random_integer" "rng_id" {
  min = 100
  max = 999
}


resource "tls_private_key" "staging_key" {
  count     = var.container.gen_keypair ? 1 : 0
  algorithm = "ED25519"
}