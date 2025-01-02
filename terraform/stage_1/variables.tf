variable "ct_image" {
  type        = string
  description = "os image for containers"
}
variable "ipv4_gw" {
  type        = string
  description = "gateway for proxmox vm's and ct's"
  default     = "192.168.0.1"
}

variable "ipv4_subnet_net" {
  type        = string
  description = "subnet network bits"
  default     = "192.168.0"
}
variable "ipv4_subnet_cidr" {
  type        = string
  description = "subnet cidr"
  default     = "/24"

}

variable "public_key" {
  type        = string
  description = "ct public key"
  sensitive   = true
}

variable "private_key" {
  type        = string
  description = "ct private key"
  sensitive   = true
}
variable "private_key_path" {
  type        = string
  description = "ct private key path"
  sensitive   = true
}

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

variable "oci_private_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "region" {
  type      = string
  default   = ""
  sensitive = true
}

variable "domain" {
  type        = string
  description = "domain name to use"
  default     = "example.com"
}

variable "extra_dns" {
  type        = any
  description = "other dns k value pair to add to blocky"
  default     = {}

}

locals {
  dns_names = {
    ca    = "${module.step_ca.hostname}.${var.domain}"
    dns   = "${module.dns.hostname}.${var.domain}"
    wg_gw = "${module.wg_gw.hostname}.${var.domain}"
    # wg_vps = "${module.wg_vps.hostname}.${var.domain}"
  }
  # wireguard = { wireguard = { hosts = merge(module.wg_gw.host, module.wg_vps.host) } }
  ca  = { ca_servers = { hosts = module.step_ca.host } }
  dns = { dns_servers = { hosts = module.dns.host } }
}


output "dns_server" {
  value = module.dns.ct_ipv4_address
}

output "ca_server" {
  value = module.dns.ct_ipv4_address
}
# 
output "wireguard_gw_server" {
  value = module.wg_gw.ct_ipv4_address
}

# output "wireguard_vps_server" {
# value = module.wg_vps.oci_public_ip
# 
# }

output "inventory" {
  value = merge(local.ca, local.dns, ) # local.wireguard

}