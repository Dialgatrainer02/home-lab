variable "container" {
  type = object({
    description  = optional(string, "Managed by terraform")
    vm_id        = optional(number, 0)
    unprivileged = optional(bool, true)
    hostname     = optional(string, "terraform")
    dns          = optional(list(string), ["1.1.1.1", "1.0.0.1"])
    ipv4_address = optional(string, "dhcp")
    ipv4_gateway = optional(string, null)
    gen_keypair  = optional(bool, true)
    public_key   = optional(string)


    cores     = optional(number, 2)
    disk      = optional(number, "5")
    memory    = optional(number, 1024)
    swap      = optional(number, 1024)
    os_image  = string
    os_type   = string
    startup   = optional(bool, true)
    host_vars = optional(any, {})
  })

}

variable "pve_address" {
  type = string
}
variable "pve_username" {
  type = string
}

variable "pve_password" {
  type = string
}

locals {
  vm_id = var.container.vm_id != 0 ? var.container.vm_id : random_integer.rng_id.result
  public_key   = var.container.gen_keypair ? tls_private_key.staging_key[0].public_key_openssh : var.container.public_key
  pve_user     = split("@", var.pve_username)[0]
  datastore_id = element(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, index(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, "local-zfs")) # match to local-zfs aka vm data storage
  node         = data.proxmox_virtual_environment_nodes.nodes.names[0]
  ipv4_address = split("/", proxmox_virtual_environment_container.proxmox_ct.initialization[0].ip_config[0].ipv4[0].address)
  host_vars    = merge(var.container.host_vars, { ansible_host = local.ipv4_address })
  host = {
    "${proxmox_virtual_environment_container.proxmox_ct.initialization[0].hostname}" = local.host_vars
  }
}

data "proxmox_virtual_environment_nodes" "nodes" {}
data "proxmox_virtual_environment_datastores" "datastores" {
  node_name = data.proxmox_virtual_environment_nodes.nodes.names[0]
}


output "ipv4_address" {
  value = local.ipv4_address
}
output "ansible_inventory" {
  value = local.host
}

output "private_key" {
  value     = var.container.gen_keypair ? tls_private_key.staging_key[0].private_key_openssh : null
  sensitive = true
}
output "public_key" {
  value = local.public_key

}