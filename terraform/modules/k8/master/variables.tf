variable "servers" {
  type    = list(string)
  default = ["master0", "master1", "master2"]
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

variable "kube_config" {
  type = object({
    cluster_endpoint = string
  })
  description = "config options to be sent to kubeadm init"
  default = {
    cluster_endpoint = "cluster-endpoint" # set to cluser endpoint to set to node ip. Swap to load balencer address/ip when needed
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