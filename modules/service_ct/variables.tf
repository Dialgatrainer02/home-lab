variable "pve_settings" {
  description = "object containing connection properties for the pve host"
  type = object({
    pve_username = string
    pve_password = string
    pve_address  = string
  })
}

locals {
  pve_user = split("@", var.pve_settings.pve_username)[0]
}

variable "service" {
  type = object({
    service_name        = string
    service_description = string
    service_ipv4 = optional(object({
      address = optional(string)
      gateway = optional(string)
    }), {})
    service_type = string
    custom_ct    = any # object to be passed to proxmox/container module to change defaults
    host_vars    = optional(any, {})
  })
}

variable "consul" {
  type = object({
    install = optional(bool, false)
    config  = optional(any, {})
  })
}

variable "alloy" {
  type = object({
    install = optional(bool, false)
    config  = optional(any, {})
  })
}

variable "dns" {
  type = object({
    entry  = optional(bool, false)
    domain = optional(string)
    url    = optional(string)
  })
}