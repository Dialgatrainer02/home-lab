variable "pve_username" {
  type      = string
  default   = ""
  sensitive = true
}

variable "pve_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "pve_address" {
  type      = string
  default   = ""
  sensitive = true
}


variable "tenancy_ocid" {
  type      = string
  default   = ""
  sensitive = true
}

variable "user_ocid" {
  type      = string
  default   = ""
  sensitive = true
}

variable "fingerprint" {
  type      = string
  default   = ""
  sensitive = true
}

variable "compartment_ocid" {
  type      = string
  default   = ""
  sensitive = true
}

variable "private_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "region" {
  type      = string
  default   = ""
  sensitive = true
}

variable "duckdns_token" {
  type      = string
  default   = ""
  sensitive = true
}
