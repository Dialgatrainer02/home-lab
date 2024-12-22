variable "playbook" {
  type        = string
  default     = ""
  description = "path to a playbook"
}
variable "inventory" {
  description = "ansible inventory file "
  type        = any
  default     = {}
}
variable "host_key_checking" {
  type        = string
  default     = "true"
  description = "set ansibles' ssh connections StrictHostKeyChecking"
}

variable "private_key_file" {
  type        = string
  description = "path to the default private key"

}

variable "ssh_user" {
  type    = string
  default = "root"
}
variable "quiet" {
  type    = bool
  default = false

}