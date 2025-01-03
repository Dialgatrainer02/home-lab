variable "helper" {
  type = object({
    callback         = optional(string, "dense")
    user             = optional(string, "root")
    private_key_file = string
  })
}
variable "alloy_vars" {
  type = any
}

variable "host" {
  type = any
}

