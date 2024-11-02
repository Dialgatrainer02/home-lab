data "proxmox_virtual_environment_nodes" "nodes" {}
data "proxmox_virtual_environment_datastores" "datastores" {
  node_name = data.proxmox_virtual_environment_nodes.nodes.names[0]
}

variable "groups" {
  type    = list(string)
  default = ["adguards", "logging", "wireguard", "arrstack", "minecraft"]
}


locals {
  datastore_id = element(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, index(data.proxmox_virtual_environment_datastores.example.datastore_ids, "local-zfs")) # match to local-zfs aka vm data storage
  node         = data.proxmox_virtual_environment_nodes.nodes.names[0]
}

data "oci_core_instance" "wireguard_instance" {
  instance_id = oci_core_instance.wireguard_instance0.id
}

variable "instance_shape" {
  default = "VM.Standard.E2.1.Micro" # "VM.Standard.A1.Flex"
}

variable "instance_ocpus" { default = 1 }

variable "instance_shape_config_memory_in_gbs" { default = 6 }

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 3
}