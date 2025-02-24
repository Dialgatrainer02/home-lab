output "private_key" {
  value = {
    for i in var.servers : "${i}" => trimspace(tls_private_key.ssh[i].private_key_openssh)
  }
}

output "ip_addresses" {
  value = {
    for i in var.servers : "${i}" => proxmox_virtual_environment_vm.worker[i].ipv4_addresses[1][0]
  }
}
