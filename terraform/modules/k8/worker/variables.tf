variable "servers" {
  type    = list(string)
  default = ["worker0", "worker1", "worker2"]
}

variable "provision_user" {
  type    = string
  default = "kubernetes"

}

variable "ip_config" {
  type = object({
    ipv4_gateway      = string
    ipv4_subnet       = string
    ipv4_cidr         = string
    ipv6_cidr         = optional(string)
    ipv6_network_bits = optional(string)
  })
  default = {
    ipv4_cidr    = "/24"
    ipv4_gateway = "192.168.0.1"
    ipv4_subnet  = "192.168.0"
  }
}

variable "master_node_config" {
  type = object({
    name             = string
    host             = string
    private_key      = string
    private_key_path = string
    user             = string
  })

}

locals {
  datastore_id = (element(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, index(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, "local-zfs"))) # match to local-zfs aka vm data storage
  node         = (data.proxmox_virtual_environment_nodes.nodes.names[0])
}

data "proxmox_virtual_environment_nodes" "nodes" {}
data "proxmox_virtual_environment_datastores" "datastores" {
  node_name = (data.proxmox_virtual_environment_nodes.nodes.names[0])
}