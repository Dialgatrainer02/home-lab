variable "ipv4_subnet_net" {
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
  domain   = "${var.duckdns_domains[0]}.duckdns.org"
  pve_user = split("@", var.pve_username)[0]
  node     = data.proxmox_virtual_environment_nodes.nodes.names[0]
}

# locals {
# logging = { grafana = { hosts = merge(module.minio.host, module.mimir.host) } }
# }