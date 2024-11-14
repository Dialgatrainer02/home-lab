# try ansible provider
# edit existing inventory file for ip addresses
#generate on in terraform using yamlencode

locals {
  hosts  = merge(var.containers, var.vms, var.oracle)
  groups = toset(flatten([for h in local.hosts : h.ansible_groups]))
  inventory = yamlencode({
    "all" = {
      "children" = {
        for group in local.groups : group => {
          hosts = { for host in keys(local.hosts) : host => {/*...*/} if contains(local.hosts[host].ansible_groups, group) 
          #  host => { 
            # "ansible_host" = "${try(oci_core_instance.wireguard_instance[host].public_ip, trimsuffix(proxmox_virtual_environment_vm.almalinux_vm[host].initialization[0].ip_config[0].ipv4[0].address, "/24"), trimsuffix(proxmox_virtual_environment_container.almalinux_container[host].initialization[0].ip_config[0].ipv4[0].address, "/24"))}"
            # "ansible_user" = "${contains(keys(var.oracle), host) ? "opc" : contains(keys(var.vms), host) ? "almalinux" : "root"}"
            # if contains(local.hosts[host],"ansible_variables") ? for k,v in host.ansible_variables: k => {v} : ""    figure out how to place ansiblr vars in here
            # }
          }
        }
      }
      "vars" = {
        "ansible_ssh_private_key_file" = "./terraform/homelab_key"
      }
    }
  })
}

output "inventory" {
  value = local.inventory

}


resource "local_file" "inventory" {
    content = local.inventory
    filename = "./terraform-inventory.yml"
}



