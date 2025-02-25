variable "servers" {
  type    = list(string)
  default = ["lb0", "lb1"]
}

variable "provision_user" {
  type    = string
  default = "lb"

}

variable "ip_config" {
  type = object({
    ipv4_gateway      = string
    ipv4_subnet       = string
    ipv4_cidr         = string
    ipv4_start_range  = number
    ipv6_cidr         = optional(string)
    ipv6_network_bits = optional(string)
  })
  default = {
    ipv4_cidr        = "/24"
    ipv4_gateway     = "192.168.0.1"
    ipv4_subnet      = "192.168.0"
    ipv4_start_range = 175
  }
}

variable "control_plane_nodes" {
  type    = list(string)
  default = ["192.168.0.200:6443", ]
}

variable "haproxy_config" {
  type = object({
    bind    = string
    balance = string
  })
  default = {
    bind    = ":6443"
    balance = "roundrobin"
  }

}

locals {
  datastore_id = (element(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, index(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, "local-zfs"))) # match to local-zfs aka vm data storage
  node         = (data.proxmox_virtual_environment_nodes.nodes.names[0])
}

data "proxmox_virtual_environment_nodes" "nodes" {}
data "proxmox_virtual_environment_datastores" "datastores" {
  node_name = (data.proxmox_virtual_environment_nodes.nodes.names[0])
}