data "proxmox_virtual_environment_nodes" "nodes" {}
data "proxmox_virtual_environment_datastores" "datastores" {
  node_name = data.proxmox_virtual_environment_nodes.nodes.names[0]
}


locals {
  pve_user     = split("@", var.pve_username)[0]
  datastore_id = element(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, index(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, "local-zfs")) # match to local-zfs aka vm data storage
  node         = data.proxmox_virtual_environment_nodes.nodes.names[0]
}

variable "vm_id" {
  description = "The VM ID to be assigned to the container."
  type        = number
  default     = 100
}

variable "hostname" {
  description = "The hostname assigned to the container."
  type        = string
  default     = "example"
}

variable "description" {
  description = "A description of the container."
  type        = string
  default     = "Managed by terraform"
}

variable "ipv4_address" {
  description = "The IPv4 address for the container."
  type        = string
  default     = "192.168.1.100"
}

variable "ipv4_gw" {
  description = "The IPv4 gateway for the container."
  type        = string
  default     = "192.168.1.1"
}

variable "dns" {
  description = "The DNS servers for the container."
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "public_key" {
  description = "The public key to be used for SSH access to the container."
  type        = any
}

variable "cores" {
  description = "The number of CPU cores to allocate to the container."
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "The size of the disk to allocate to the container (e.g., '10G')."
  type        = string
  default     = "10G"
}

variable "mem_size" {
  description = "The amount of dedicated memory to allocate to the container (in MB)."
  type        = number
  default     = 2048
}

variable "swap_size" {
  description = "The amount of swap memory to allocate to the container (in MB)."
  type        = number
  default     = 1024
}

variable "os_image" {
  description = "The OS image template file ID for the container."
  type        = any #should be string but passing in resources means it has to be object or any
}

variable "pve_address" {
  description = "The address of the Proxmox VE host."
  type        = string
}

variable "pve_username" {
  description = "the username for connecting to the Proxmox VE host."
  type        = string
}

variable "pve_password" {
  description = "The password for connecting to the Proxmox VE host."
  type        = string
}

output "ct_public_key" {
  value = proxmox_virtual_environment_container.proxmox_ct.initialization[0].user_account[0].keys[0]
}

output "ct_ipv4_address" {
  value = proxmox_virtual_environment_container.proxmox_ct.initialization[0].ip_config[0].ipv4[0].address
}