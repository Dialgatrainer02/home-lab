# try ansible provider
# edit existing inventory file for ip addresses
#generate on in terraform using yamlencode

locals {
    hosts = merge(var.containers, var.vms, var.oracle)
    groups = toset(flatten([for h in local.hosts : h.ansible_groups]))
}

output "ansible_groups" {
  value = local.groups
}