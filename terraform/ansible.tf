
resource "ansible_group" "group" {
    for_each = var.containers
    name = each.key
}

# lxc hosts
resource "ansible_host" "host" {
    for_each = var.containers

    name =  each.key
    groups = var.containers[each.key].ansible_groups
    variables = merge([var.containers[each.key].ansible_varibles, {ansible_user = "root", ansible_host = "${proxmox_virtual_environment_container.almalinux_container[each.key].initalization.ip_config.ipv4.address}" }]) 
}

#qemu hosts
resource "ansible_host" "host" {
    for_each = var.vms  

    name = each.key
    groups = var.vms[each.key].ansible_groups
    variables = merge([var.containers[each.key].ansible_varibles, {ansible_user = "root", ansible_host = "${proxmox_virtual_environment_vm.almalinux_vm[each.key].initalization.ip_config.ipv4.address}" }]) 
}

# oracle vps
resource "ansible_host" "host" {
    name = "${each.key}"
    groups = var.oracle[each.key].ansible_groups
    variables = merge([var.containers[each.key].ansible_varibles, {ansible_user = "opc", ansible_host = "${data.oci_core_instance.wireguard_instance.public_ip}" }]) 
}