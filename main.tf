locals {
  pve_settings = {
    pve_address  = var.pve_address
    pve_password = var.pve_password
    pve_username = var.pve_username
  }
}
resource "proxmox_virtual_environment_download_file" "release_almalinux_9_4_lxc_img" {
  connection { # kinda hacky way to make the directory
    host     = var.pve_address
    type     = "ssh"
    user     = local.pve_user
    password = var.pve_password
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /mnt/bindmounts/terraform"
    ]
  }
  overwrite_unmanaged = true
  content_type        = "vztmpl"
  datastore_id        = "local"
  node_name           = local.node
  url                 = "http://download.proxmox.com/images/system/almalinux-9-default_20240911_amd64.tar.xz"
}

locals {
  dns_servers = {
    inventory = merge(module.dns-1.service_inventory, module.dns-0.service_inventory)
    addrs     = [module.dns-1.service_ipv4_address, module.dns-0.service_ipv4_address]
  }
}
module "dns-0" {
  source = "./modules/service_ct"

  pve_settings = local.pve_settings
  service = {
    service_name        = "dns-0"
    service_type        = "dns"
    service_description = "dns server 0"
    service_os_image    = proxmox_virtual_environment_download_file.release_almalinux_9_4_lxc_img.id
    service_os_type     = "centos"
    service_ipv4 = {
      ipv4_address = "${var.ipv4_network_bits}.200${var.ipv4_cidr}"
      ipv4_gateway = var.ipv4_gateway
    }
    custom_ct = {
      startup = true
      cores   = 1
      host_vars = {
        ansible_ssh_private_key_file = ".keys/dns-0_private_key"
      }
    }
  }
  alloy = {
    install = true
    endpoints = {
      prom = "http://192.168.0.112:9090/api/v1/write"
      loki = "http://192.168.0.112:3100/loki/api/v1/push"
    }
  }
  consul = {
    install = false
  }
  dns = {
    entry = true
    # private_key_path = module.dns-0.service_private_key_path
    host = local.dns_servers.inventory
  }
  service_vars = {
    dnsmasq_domain           = "internal"
    dnsmasq_expand_hosts     = true
    dnsmasq_upstream_servers = ["1.1.1.1", "1.0.0.1"]
    dnsmasq_addn_hosts       = "/etc/hosts.d"
    dnsmasq_blocklists = [
      "https://raw.githubusercontent.com/StevenBlack/hosts/refs/heads/master/hosts",
      "https://hosts.tweedge.net/malicious.txt",
    ]
  }
}


module "dns-1" {
  source = "./modules/service_ct"

  pve_settings = local.pve_settings
  service = {
    service_name        = "dns-1"
    service_type        = "dns"
    service_description = "dns server 1"
    service_os_image    = proxmox_virtual_environment_download_file.release_almalinux_9_4_lxc_img.id
    service_os_type     = "centos"
    service_ipv4 = {
      ipv4_address = "${var.ipv4_network_bits}.201${var.ipv4_cidr}"
      ipv4_gateway = var.ipv4_gateway
    }
    custom_ct = {
      startup = true
      cores   = 1
      host_vars = {
        ansible_ssh_private_key_file = ".keys/dns-1_private_key"
      }
    }
  }
  alloy = {
    install = true
    endpoints = {
      prom = "http://192.168.0.112:9090/api/v1/write"
      loki = "http://192.168.0.112:3100/loki/api/v1/push"
    }
  }
  consul = {
    install = false
  }
  dns = {
    entry = true
    # private_key_path = module.dns-1.service_private_key_path
    host = local.dns_servers.inventory
  }
  service_vars = {
    dnsmasq_domain           = "internal"
    dnsmasq_expand_hosts     = true
    dnsmasq_upstream_servers = ["1.1.1.1", "1.0.0.1"]
    dnsmasq_addn_hosts       = "/etc/hosts.d"
    dnsmasq_blocklists = [
      "https://raw.githubusercontent.com/StevenBlack/hosts/refs/heads/master/hosts",
      "https://hosts.tweedge.net/malicious.txt",
    ]
  }
}



module "step_ca" {
  source = "./modules/service_ct"

  pve_settings = local.pve_settings
  service = {
    service_name        = "step-1"
    service_type        = "ca"
    service_description = "small step ca server 1"
    service_os_image    = proxmox_virtual_environment_download_file.release_almalinux_9_4_lxc_img.id
    service_os_type     = "centos"
    service_ipv4 = {
      ipv4_address = "${var.ipv4_network_bits}.202${var.ipv4_cidr}"
      ipv4_gateway = var.ipv4_gateway
    }
    custom_ct = {
      startup = true
      cores   = 1
      dns     = local.dns_servers.addrs
    }
  }
  alloy = {
    install = true
    endpoints = {
      prom = "http://192.168.0.112:9090/api/v1/write"
      loki = "http://192.168.0.112:3100/loki/api/v1/push"
    }
  }
  consul = {
    install = false
  }
  dns = {
    entry            = true
    private_key_path = module.dns-1.service_private_key_path
    host             = module.dns-1.service_ipv4_address
  }
  service_vars = {
    step_ca_name                  = "homelab inc"
    step_ca_root_password         = var.pve_password
    step_ca_intermediate_password = var.pve_password
  }
}


