locals {
    # Outputs should always be based on the actual resources and never inputs, as providers
    # tend to generate things dynamically. This also plays to TF strengths with dependency graphs
    inventory_children = merge({ for k, attrs in oci_core_instance.wireguard_instance : 
        attrs.display_name => merge({
            ansible_host = attrs.public_ip
            ansible_user = "opc"
        }, try(var.oracle.ansible_varibles, {}))
    }, { for k, attrs in proxmox_virtual_environment_vm.almalinux_vm : 
        attrs.name => merge({
            ansible_host = attrs.initialization[0].ip_config[0].ipv4[0].address
            ansible_user = "almalinux"
        }, try(var.vms.ansible_varibles,{}))
    }, { for k, attrs in proxmox_virtual_environment_container.almalinux_container : 
        attrs.name => merge({
            ansible_host = attrs.initialization[0].ip_config[0].ipv4[0].address
            ansible_user = "root"
        }, try(var.containers.ansible_varibles, {}))
    },  { for k, attrs in proxmox_virtual_environment_container.almalinux_dns : 
        attrs.name => merge({
            ansible_host = attrs.initialization[0].ip_config[0].ipv4[0].address
            ansible_user = "root"
        }, try(var.dns_servers.ansible_varibles, {}))
      }
    )
    bootstrap_inventory_children = merge({ for k, attrs in oci_core_instance.wireguard_instance : 
        attrs.display_name => merge({
            ansible_host = attrs.public_ip
            ansible_user = "opc"
        }, try(var.dns_servers.ansible_varibles, {}))
    },)
}

# One'd expect to output YAML, not directly make a YAML string in Terraform-land (local.hosts)
# so let's move it here
output "inventory" {
  value = yamlencode({
    all = {
        children = local.inventory_children
    }
    vars = {
        ansible_ssh_private_key_file = "./terraform/${local_sensitive_file.homelab_key.filename}"
    }
  })
}

output "bootstrap_inventory" {
  value = yamlencode({
    all = {
         children = local.bootstrap_inventory_children
    }
    vars = {
         ansible_ssh_private_key_file = "./terraform/${local_sensitive_file.homelab_key.filename}"
    }
  })
}