data "proxmox_virtual_environment_nodes" "nodes" {}
data "proxmox_virtual_environment_datastores" "datastores" {
  node_name = data.proxmox_virtual_environment_nodes.nodes.names[0]
}


locals {
  #   pve_user     = split("@", var.pve_username)[0]
  datastore_id = element(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, index(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, "local-zfs")) # match to local-zfs aka vm data storage
  node         = data.proxmox_virtual_environment_nodes.nodes.names[0]
  cidr         = join("", ["/", split("/", proxmox_virtual_environment_vm.proxmox_vm.initialization[0].ip_config[0].ipv4[0].address)[1]])
  ipv4_address = trimsuffix(proxmox_virtual_environment_vm.proxmox_vm.initialization[0].ip_config[0].ipv4[0].address, local.cidr)

  host = {
    "${var.name}" = {
      ansible_host = local.ipv4_address
    }
  }
}

variable "name" {
  description = "The name of the virtual machine."
  type        = string
  default     = "example-vm"
}

variable "description" {
  description = "A description of the container."
  type        = string
  default     = "Managed by terraform"
}

variable "vm_id" {
  description = "The VM ID to be assigned to the virtual machine."
  type        = number
  default     = 100
}

variable "agent" {
  description = "Specifies whether the VM agent is enabled."
  type        = bool
  default     = true
}

variable "ipv4_address" {
  description = "The IPv4 address for the virtual machine."
  type        = string
  default     = "192.168.1.150"
}

variable "ipv4_gw" {
  description = "The IPv4 gateway for the virtual machine."
  type        = string
  default     = "192.168.1.1"
}

variable "dns" {
  description = "The DNS servers for the container."
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "public_key" {
  description = "The public key to be used for SSH access to the virtual machine."
  type        = string
}

variable "username" {
  description = "The username to be created for accessing the virtual machine."
  type        = string
  default     = "root"
}

variable "cores" {
  description = "The number of CPU cores to allocate to the virtual machine."
  type        = number
  default     = 4
}

variable "mem_size" {
  description = "The amount of dedicated memory to allocate to the virtual machine (in MB)."
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "The size of the disk to allocate to the virtual machine (e.g., '20G')."
  type        = string
  default     = "20G"
}

variable "os_image" {
  description = "The OS image template file ID for the vm."
  type        = string
}

variable "os_image_type" {
  description = "The OS image template file type for the vm."
  type        = string
  default     = "qcow2"
}

output "ct_public_key" {
  value = proxmox_virtual_environment_vm.proxmox_vm.initialization[0].user_account[0].keys[0]
}

output "ct_ipv4_address" {
  value = proxmox_virtual_environment_vm.proxmox_vm.initialization[0].ip_config[0].ipv4[0].address
}

output "host" {
  value = local.host
}