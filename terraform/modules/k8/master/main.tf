resource "tls_private_key" "ssh" {
  for_each  = var.servers
  algorithm = "ED25519"
}

resource "local_sensitive_file" "private_key" {
  for_each = var.servers
  filename = "${path.root}/secret/${each.value}"
  content  = trimspace(tls_private_key.ssh[each.value].private_key_openssh)
}

resource "random_integer" "vm_id" {
  for_each = var.servers
  min      = 100
  max      = 800
}

resource "proxmox_virtual_environment_vm" "master" {
  for_each = var.servers

  node_name = local.node
  vm_id     = random_integer.vm_id[each.value].result
  name      = each.value

  bios    = "ovmf"
  machine = "q35"
  clone {
    vm_id        = 900
    datastore_id = local.datastore_id
  }

  agent {
    enabled = true
  }

}