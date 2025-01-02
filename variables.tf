variable "pve_username" {
  type      = string
  sensitive = true
}

variable "pve_password" {
  type      = string
  sensitive = true
}

variable "pve_address" {
  type      = string
  sensitive = true
}


variable "tenancy_ocid" {
  type      = string
  sensitive = true
}

variable "user_ocid" {
  type      = string
  sensitive = true
}

variable "fingerprint" {
  type      = string
  sensitive = true
}

variable "compartment_ocid" {
  type      = string
  sensitive = true
}

variable "oci_private_key" {
  type      = string
  sensitive = true
}

variable "region" {
  type      = string
  sensitive = true
}




variable "ipv4_network_bits" {
  type = string
}

variable "ipv4_cidr" {
  type = string
}

variable "ipv6_network_bits" {
  type = string
}

variable "ipv6_cidr" {
  type = string
}


locals {
  pve_user = split("@", var.pve_username)[0]
}