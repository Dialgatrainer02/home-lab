variable "pve_username" {
  description = "username of proxmox VE server"
  type        = string
  sensitive   = true
}

variable "pve_password" {
  description = "password of proxmox VE server"
  type        = string
  sensitive   = true
}

variable "pve_address" {
  description = "  ip address of proxmox VE server"
  type        = string
  sensitive   = true
}


variable "tenancy_ocid" {
  description = "tennancy ocid for oracle cloud infrastructure"
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "user ocid for oracle cloud infrastructure"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "the fingerpring of the private api key for oracle cloud infrastructure"
  type        = string
  sensitive   = true
}

variable "compartment_ocid" {
  description = "compartment ocid for oracle cloud infrastructure"
  type        = string
  sensitive   = true
}

variable "oci_private_key" {
  description = "the private api key for oracle cloud infrastructure"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "reigion for oracle cloud infrastructure"
  type        = string
  sensitive   = true
}

variable "ipv4_network_bits" {
  description = "the network bits of the lan network (ipv4)"
  type        = string
}

variable "ipv4_cidr" {
  description = "the cidr of the current subnet (ipv4)"
  type        = string
}

variable "ipv6_network_bits" {
  description = "the network bits of the lan network (ipv6)"
  type        = string
}

variable "ipv6_cidr" {
  description = "the cidr of the current subnet (ipv6)"
  type        = string
}


locals {
  pve_user = split("@", var.pve_username)[0]
}