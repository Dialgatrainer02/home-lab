output "ip_address" {
  value = (proxmox_virtual_environment_vm.nfs_server.ipv4_addresses[1][0])

}

output "private_key" {
  value = (trimspace(tls_private_key.ssh.private_key_openssh))
}

output "private_key_paths" {
  value = (local_sensitive_file.private_key.filename)
}