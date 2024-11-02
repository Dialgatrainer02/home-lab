data "proxmox_virtual_environment_nodes" "nodes" {}
data "proxmox_virtual_environment_datastores" "datastores" {
  node_name = data.proxmox_virtual_environment_nodes.nodes.names[0]
}

variable "groups" {
  type    = list(string)
  default = ["adguards", "logging", "wireguard", "arrstack", "minecraft"]
}


locals {
  datastore_id = element(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, index(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, "local-zfs")) # match to local-zfs aka vm data storage
  node         = data.proxmox_virtual_environment_nodes.nodes.names[0]
}

locals {
  container_id = {
          for idx, machine in var.containers: 
              machine.key => idx + 100
          }
}

locals {
  virtual_machine_id = {
    {for k,v in keys(var.vms) : k => v + 200 }
  }
}

data "oci_core_instance" "wireguard_instance" {
  for_each = var.oracle
  instance_id = oci_core_instance.wireguard_instance[each.key].id
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

data "oci_core_images" "images" {
  compartment_id = var.compartment_ocid
  # operating_system = "almalinux"
}