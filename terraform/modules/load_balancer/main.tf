locals {
  servers = toset(var.servers)
}

resource "tls_private_key" "ssh" {
  for_each  = (local.servers)
  algorithm = "ED25519"
}

resource "local_sensitive_file" "private_key" {
  for_each = (local.servers)
  filename = "${path.root}/secrets/keys/${each.value}-key"
  content  = (tls_private_key.ssh[each.value].private_key_openssh)
}

resource "local_sensitive_file" "worker_ssh_config" {
  filename = "${path.root}/secrets/lb_ssh_config"

  content = templatefile("${path.module}/templates/ssh_config.tftpl", merge(local.server_ssh_config, { provision_user : (var.provision_user) }))

}

locals {
  server_ssh_config = { servers = { for s in var.servers : s => {
    ip_address = (proxmox_virtual_environment_vm.lb[s].ipv4_addresses[1][0])
    id_file    = (local_sensitive_file.private_key[s].filename)
  } } }
}


resource "random_integer" "vm_id" {
  for_each = (local.servers)
  min      = 300
  max      = 400
}

resource "proxmox_virtual_environment_vm" "lb" {
  for_each = (local.servers)


  node_name = (local.node)
  vm_id     = (random_integer.vm_id[each.value].result)
  name      = (each.value)
  tags      = ["almalinux", "haproxy", "keepalived", "load-balancer", "terraform"]

  bios    = "ovmf"
  machine = "q35"
  clone {
    vm_id        = 903
    datastore_id = (local.datastore_id)
  }

  initialization {
    datastore_id = (local.datastore_id)

    ip_config {
      ipv4 {
        address = "${var.ip_config.ipv4_subnet}.${index(var.servers, each.value) + (var.ip_config.ipv4_start_range)}${var.ip_config.ipv4_cidr}"
        gateway = (var.ip_config.ipv4_gateway)
      }
    }
    user_account {
      username = (var.provision_user)
      keys     = [(trimspace(tls_private_key.ssh[each.value].public_key_openssh))]
    }
  }

  # reboot = true1
  # connection {
    # type        = "ssh"
    # host        = (self.ipv4_addresses[1][0])
    # user        = (var.provision_user)
    # private_key = (trimspace(tls_private_key.ssh[each.value].private_key_openssh))
  # }

}

resource "terraform_data" "haproxy_setup" {
  for_each = (local.servers)
  connection {
    host        = (proxmox_virtual_environment_vm.lb[each.value].ipv4_addresses[1][0])
    user        = (var.provision_user)
    private_key = (trimspace(tls_private_key.ssh[each.value].private_key_openssh))
  }

  provisioner "remote-exec" {
    inline = ["echo '${templatefile("${path.module}/templates/haproxy.cfg.tftpl", local.haproxy_config)}' | doas tee /etc/haproxy/haproxy.cfg",
    "doas service haproxy restart"]
  }
}

locals {
  haproxy_config = { config = {
    servers = (var.control_plane_nodes)
    bind    = (var.haproxy_config.bind)
    balance = (var.haproxy_config.balance)
  } }
}