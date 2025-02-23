locals {
  servers   = toset(var.servers)
}

resource "tls_private_key" "ssh" {
  for_each  = local.servers
  algorithm = "ED25519"
}


resource "random_integer" "vm_id" {
  for_each = local.servers
  min      = 100
  max      = 200
}

resource "proxmox_virtual_environment_vm" "master" {
  for_each = local.servers

  node_name = local.node
  vm_id     = random_integer.vm_id[each.value].result
  name      = each.value
  tags = ["almalinux","k8","master","terraform"]

  bios    = "ovmf"
  machine = "q35"
  clone {
    vm_id        = 900
    datastore_id = local.datastore_id
  }

  initialization {
    datastore_id = local.datastore_id

    ip_config {
      ipv4 {
        address = "${var.ip_config.ipv4_subnet}.${index(var.servers, each.value) + 200}${var.ip_config.ipv4_cidr}"
        gateway = var.ip_config.ipv4_gateway
      }
    }
    user_account {
      username = "provision"
      keys     = [trimspace(tls_private_key.ssh[each.value].public_key_openssh)]
    }
  }

  connection {
    type        = "ssh"
    host        = self.ipv4_addresses[1][0]
    user        = "provision"
    private_key = trimspace(tls_private_key.ssh[each.value].private_key_openssh)
  }

}