variable "ansible_settings" {
  type = object({
    host_key_checking = optional(string, "accept-new")
    private_key_file  = string
    ssh_user          = optional(string, "root")
    ansible_callback  = optional(string, "dense")
  })
}

variable "inventory" {
  type = any
}

variable "playbook_path" {
  type = string
}

variable "extra_vars" {
  type    = any
  default = {}
}