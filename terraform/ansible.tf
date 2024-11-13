# try ansible provider
# edit existing inventory file for ip addresses
#generate on in terraform using yamlencode

locals {
  hosts  = merge(var.containers, var.vms, var.oracle)
  groups = toset(flatten([for h in local.hosts : h.ansible_groups]))
  inventory = yamlencode({
    for group in local.groups: group => {
      hosts = {for host in keys(local.hosts): host => {
          "ansible_host" = "${try(oci_core_instance.wireguard_instance[host].public_ip, proxmox_virtual_environment_vm.almalinux_vm[host].initialization[0].ip_config[0].ipv4[0].address, proxmox_virtual_environment_container.almalinux_container[host].initialization[0].ip_config[0].ipv4[0].address )}"
          "ansible_user" = "${contains(keys(var.oracle), host) ? "opc": contains(keys(var.vms), host) ? "almalinux": "root"}"
        }
      }
    }
  })
}

output "inventory" {
  value = local.inventory
}




