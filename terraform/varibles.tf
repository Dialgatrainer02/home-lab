variable "ipv4_subnet_pre" {
  type    = string
  default = "192.168.1"
}

variable "ipv4_subnet_cidr" {
  type    = string
  default = "/24"
}

variable "duckdns_domains" {
  type    = list(string)
  default = [""]
}

data "proxmox_virtual_environment_nodes" "nodes" {}
data "proxmox_virtual_environment_datastores" "datastores" {
  node_name = data.proxmox_virtual_environment_nodes.nodes.names[0]
}


locals {
  pve_user     = split("@", var.pve_username)[0]
  datastore_id = element(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, index(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, "local-zfs")) # match to local-zfs aka vm data storage
  node         = data.proxmox_virtual_environment_nodes.nodes.names[0]
}