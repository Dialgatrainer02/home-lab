variable "ipv4_subnet_pre" {
  type    = string
  default = "192.168.1"
}

variable "ipv4_subnet_cidr" {
  type    = string
  default = "/24"
}

variable "duckdns_domains" {
  type    = list(string)
  default = [""]
}