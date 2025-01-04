output "service_ipv4_address" {
  value = module.service_ct.ipv4_address
}

output "service_inventory" {
  value = module.service_ct.ansible_inventory
}

output "service_private_key" {
  value = module.service_ct.private_key
}

output "service_private_key_path" {
  value = local_sensitive_file.service_private_key.filename
  
}

output "service_public_key" {
  value = module.service_ct.public_key
}
