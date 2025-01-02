locals {
  logging = {
    grafana = {
      hosts = merge(
        module.minio.host,
        module.mimir.host,
        module.loki.host,
        module.grafana.host
      )
    }
  }
}


variable "domain" {
  type        = string
  description = "domain name to use"
  default     = "example.com"
}

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

variable "alloy_hosts" {
  
}

output "minio_server" {
  value = module.minio.ct_ipv4_address
}

output "mimir_server" {
  value = module.mimr.ct_ipv4_address
}
# 
output "loki_server" {
  value = module.loki.ct_ipv4_address
}

output "grafana_server" {
  value = module.grafana.ct_ipv4_address
}


output "inventory" {
  value =  local.logging
}

output "dns_names" {
  value = {
    minio    = "${module.minio.hostname}.${var.domain}"
    mimir  = "${module.mimir.hostname}.${var.domain}"
    loki = "${module.loki.hostname}.${var.domain}"
    grafana = "${module.grafana.hostname}.${var.domain}"
  }
  
}