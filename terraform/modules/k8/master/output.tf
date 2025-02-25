output "private_keys" {
  value = {
    for i in var.servers : (i) => (trimspace(tls_private_key.ssh[i].private_key_openssh))
  }
}

output "private_key_paths" {
  value = {
    for i in var.servers : (i) => (local_sensitive_file.private_key[i].filename)
  }
}

output "ip_addresses" {
  value = {
    for i in var.servers : (i) => (proxmox_virtual_environment_vm.master[i].ipv4_addresses[1][0])
  }
}