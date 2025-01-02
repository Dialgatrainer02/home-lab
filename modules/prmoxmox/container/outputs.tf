output "ipv4_address" {
    description = "containers ip address"
  value = local.ipv4_address
}
output "ansible_inventory" {
    description = "a ansible_inventoty snippet for running playbooks"
  value = local.host
}

output "private_key" {
    description = "private key of the created container"
  value     = var.container.gen_keypair ? tls_private_key.staging_key[0].private_key_openssh : null
  sensitive = true
}
output "public_key" {
    description = "public key of the created container"
  value = local.public_key

}