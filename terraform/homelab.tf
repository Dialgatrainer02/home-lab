terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.66.3"
    }
     ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.2"
    }
  }
}

provider "proxmox" {
  endpoint = var.pve_endpoint

  username = var.pve_username
  password = var.pve_password
  insecure = true
  tmp_dir  = "/tmp"
}

resource "proxmox_virtual_environment_download_file" "release_almalinux_9-4_lxc_img" {
  content_type       = "vztmpl"
  datastore_id       = "local"
  node_name          = "pve"
  url                = "http://download.proxmox.com/images/system/almalinux-9-default_20240911_amd64.tar.xz"
}

resource "proxmox_virtual_environment_download_file" "latest_almalinux_9-4_qcow2" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  url          = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-9.4-20240507.x86_64.qcow2"
  file_name    = "almalinux_9-4.img"
}



data "proxmox_virtual_environment_nodes" "nodes" {}
data "proxmox_virtual_environment_datastores" "datastores" {
    node_name = data.proxmox_virtual_environment_nodes.nodes.names[0]
}

variable "groups" {
  type =  list(string)
  default = [ "adguards", "logging","wireguard","arrstack","minecraft" ] 
}

variable "containers" {
    type = map(any)

    default = {
        adguard1 = {
            ansible_groups = ["adguards"]
            ansible_varibles = {""}
        }
        adguard2 = {
            ansible_groups = ["adguards"]
            ansible_varibles = {""}
        }
        prometheus = {
            ansible_groups = ["logging"]
        }
        loki = {
            ansible_groups = ["logging"]
        }
        grafana = {
            ansible_groups = ["logging"]
        }
        wireguard-oci = {
            ansible_groups = ["wireguard"]
            ansible_varibles = {
                wireguard_interface = "wg0"
                wireguard_interface_restart = true
                wireguard_port = "51820"
                wireguard_address = "10.50.0.1/24"
                wireguard_endpoint = "oc-1-vps.duckdns.org"
                wireguard_allowed_ips = "0.0.0.0/0"
                wireguard_postup = yamlencode(["nft add table inet wireguard; nft add chain inet wireguard wireguard_chain {type nat hook postrouting priority srcnat\; policy accept\;}; nft add rule inet wireguard wireguard_chain counter packets 0 bytes 0 masquerade;"])
                wireguard_postdown =  yamlencode(["nft delete table inet wireguard;"])
            }
        }
    }
}

variable "vms" {
    type = map(any)

    default = {
        docker = {
            ansible_groups = ["wireguard","arrstack","minecraft"]
            ansible_varibles = {
                wireguard_remote_directory = "/opt/arrstack/config/wireguard"
                wireguard_service_enabled = "no"
                wireguard_service_state = "stopped"
                wireguard_interface = "wg0"
                wireguard_port = "51820"
                wireguard_address = "10.50.0.2/24"
                wireguard_endpoint = "hn-1-prx.duckdns.org"
                wireguard_allowed_ips = "10.50.0.2/32"
                wireguard_persistent_keepalive = "30"
            }
        }
    }
}

locals {
  datastore_id = element(data.proxmox_virtual_environment_datastores.datastores.datastore_ids, index(data.proxmox_virtual_environment_datastores.example.datastore_ids, "local-zfs")) # match to local-zfs aka vm data storage
  node = data.proxmox_virtual_environment_nodes.nodes.names[0]
}


resource "tls_private_key" "homelab-key" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "lxc_key" {
  content = tls_private_key.homelab-key.private_key_openssh
  filename = "${path.module}/lxc_key"
}

resource "ansible_group" "group" {
    for_each = var.containers
    name = each.key
}

resource "proxmox_virtual_environment_container" "almalinux_container" {
  for_each = var.containers
  octet = index(var.containers, each.value) + 100
  description = "Managed by Terraform"

  started = true
  node_name = "${node}"
  vm_id     = "${octet}"

  initialization {
    hostname = each.key

    ip_config {
      ipv4 {
        address = "192.168.0.${octet}/24"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      keys = [
        trimspace(tls_private_key.lxc_key.public_key_openssh)
      ]
    }
  }
  cpu {
    cores = "2"
  }

  disk {
    datastore_id = local.datastore_id
    size = "4G"
  }
  memory {
    dedicated = "2048"
    swap = "1024"
  }

  network_interface {
    name = "veth0"
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.latest_almalinux_9-4_lxc_img.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type             = "centos"
  }
  start_on_boot = "true"
}

resource "proxmox_virtual_environment_vm" "almalinux_vm" {
    for_each = var.vms
    octet = index(var.vms, each.value) + 200 # technically limited to 54 vm's now but that will be engough
    name      = each.key
    vm_id = "${octet}"
    node_name = "${node}"
    
    started = "true"
    on_boot = "true"
    bios = "ovmf"
    machine = "q35"
    
    initialization {
        ip_config {
        ipv4 {
            address = "192.168.0.${octet}/24"
            gateway = "192.168.0.1"
        }
        }
    
        machine = "q35"
    
        user_account {
        keys     = [trimspace(tls_private_key.lxc_key.public_key_openssh)]
        }
    }

    cpu {
        type = "host"
        cores = 2
    }
    memory {
        dedicated = 2048
    }
    
    disk {
        datastore_id = local.datastore_id
        file_id      = proxmox_virtual_environment_download_file.latest_almalinux_9-4_qcow2.id
        interface    = "virtio0"
        iothread     = true
        discard      = "on"
        size         = 10
    }
    
    efi_disk {
        datastore_id = local.datastore_id
        file_format  = "raw"
        type         = "4m"
    }
    
    network_device {
        bridge = "vmbr0"
    }

    operating_system {
        type = "l26"
    }
}

# lxc hosts
resource "ansible_host" "host" {
    for_each = var.containers

    name =  each.key
    groups = var.containers[each.key].ansible_groups
    varibles = merge([var.containers[each.key].ansible_varibles, {ansible_user = "root", ansible_host = "${proxmox_virtual_environment_container.almalinux_container[each.key].initalization.ip_config.ipv4.address}" }]) 
}

#qemu hosts
resource "ansible_host" "host" {
    forfor_each = var.vms  

    name = each.key
    groups = var.vms[each.key].ansible_groups
    varibles = merge([var.containers[each.key].ansible_varibles, {ansible_user = "root", ansible_host = "${proxmox_virtual_environment_vm.almalinux_vm[each.key].initalization.ip_config.ipv4.address}" }]) 
}



#outputs the private key
output "homelab-key" {
  value = tls_private_key.homelab-key.private_key_openssh
  sensitive = true
}