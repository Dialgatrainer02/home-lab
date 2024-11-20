# try ansible provider
# edit existing inventory file for ip addresses
#generate on in terraform using yamlencode

locals {
  hosts  = merge(var.dns_servers, var.containers, var.vms, var.oracle)
  groups = toset(flatten([for h in local.hosts : h.ansible_groups]))
  hostvars_raw = {
    for k in keys(local.hosts) : k => local.hosts[k].ansible_varibles 
  }
  # hostvars = {
    # for host in keys(local.hostvars_raw): host => {
      # for k,v in local.hostvars_raw[host]: k=>v
    # }
  # }
  inventory = yamlencode({
    "all" = {
      "children" = {
        for group in local.groups : group => {
          hosts = {
            for host in keys(local.hosts) : host => {
              "ansible_host" = "${contains(keys(var.oracle), host) ? oci_core_instance.wireguard_instance[host].public_ip : contains(keys(var.vms), host) ? trimsuffix(proxmox_virtual_environment_vm.almalinux_vm[host].initialization[0].ip_config[0].ipv4[0].address, "/24") : contains(keys(var.containers), host) ? trimsuffix(proxmox_virtual_environment_container.almalinux_container[host].initialization[0].ip_config[0].ipv4[0].address, "/24") : contains(keys(var.dns_servers), host) ? trimsuffix(proxmox_virtual_environment_container.almalinux_dns[host].initialization[0].ip_config[0].ipv4[0].address, "/24") : "null"}",
              "ansible_user" = "${contains(keys(var.oracle), host) ? "opc" : contains(keys(var.vms), host) ? "almalinux" : "root"}"
              # "vars" = { #TODO using vars child element doesnt work
                # for k,v in local.hostvars[host]: k => v  
              # }
            } if contains(local.hosts[host].ansible_groups, group)
          }
        }
      }
      "vars" = {
        "ansible_ssh_private_key_file" = "./terraform/${local_sensitive_file.homelab_key.filename}"
      }
    }
    }
  )
  bootstrap = yamlencode({
    "all" = {
      "children" = {
        "dns" = {
          "hosts" = {
            for host in keys(var.dns_servers) : host => {
              "ansible_host" = "${trimsuffix(proxmox_virtual_environment_container.almalinux_dns[host].initialization[0].ip_config[0].ipv4[0].address, "/24")}"
              "ansible_user" = "root"
            }
          }
        }
      }
      "vars" = {
        "ansible_ssh_private_key_file" = "./terraform/${local_sensitive_file.homelab_key.filename}"
      }
    }
  })
}

output "hostvars" {
  value = local.hostvars_raw
}
output "inventory" {
  value = local.inventory

}
resource "local_file" "bootstrap" {
  content  = local.bootstrap
  filename = "./bootstrap-inventory.yml"

}

resource "local_file" "inventory" {
  content  = local.inventory
  filename = "./terraform-inventory.yml"
}



