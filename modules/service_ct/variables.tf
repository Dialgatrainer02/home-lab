variable "pve_settings" {
  description = "object containing connection properties for the pve host"
  type = object({
    pve_username = string
    pve_password = string
    pve_address  = string
  })
}

locals {
  private_key = coalesce(module.service_ct.private_key, var.service.service_private_key)
}

variable "service" {
  type = object({
    service_name        = string
    service_description = string
    service_ipv4 = optional(object({
      ipv4_address = optional(string)
      ipv4_gateway = optional(string)
    }), {})
    service_os_image    = string
    service_os_type     = string
    service_type        = string
    service_private_key = optional(string, null) # only use with custom_ct.public_key
    custom_ct           = any
    host_vars           = optional(any, {})
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

variable "service_vars" {
  type    = any
  default = {}

}