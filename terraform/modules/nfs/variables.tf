variable "allowed_addresses" {
  type    = list(string)
  default = ["192.168.0.0/24"]
}

variable "nfs_mount_points" {
  type        = list(string)
  default     = ["/mnt"]
  description = "first in list is root fsid in nfs"
}

variable "provision_user" {
  type    = string
  default = "nfs"

}

variable "usb_passthrough" {
  type = object({
    host    = optional(string)
    mapping = optional(string)
    usb3    = optional(bool)
    fstype  = optional(string)
  })
  default = null

}

variable "vm_name" {
  type    = string
  default = "nfs0"
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

locals {
  datastore_id = element(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, index(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, "local-zfs")) # match to local-zfs aka vm data storage
  node         = data.proxmox_virtual_environment_nodes.nodes.names[0]
}

data "proxmox_virtual_environment_nodes" "nodes" {}
data "proxmox_virtual_environment_datastores" "datastores" {
  node_name = data.proxmox_virtual_environment_nodes.nodes.names[0]
}