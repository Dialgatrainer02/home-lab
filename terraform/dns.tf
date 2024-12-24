module "dns-1" {
  source       = "${path.root}/modules/proxmox_ct"
  vm_id        = 201
  hostname     = "dns-1"
  description  = "dns  server"
  ipv4_address = "${var.ipv4_subnet_pre}.201${var.ipv4_subnet_cidr}"
  ipv4_gw      = "192.168.0.1"
  dns          = ["1.1.1.1", "1.0.0.1"]
  public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}

module "configure_dns" {
  source     = "./modules/playbook"
  depends_on = [module.dns-1]

  playbook          = "../ansible/dns-playbook.yml" # from root not module
  host_key_checking = "false"
  private_key_file  = local_sensitive_file.private_staging_key.filename
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    duckdns_domains  = var.duckdns_domains
    host_dns_enabled = false
  }
  inventory = {
    # all = {
    # children = {
    # "dns" = null
    # }
    # }
    dns = {
      hosts = {
        dns-1 = {
          ansible_host = trimsuffix(module.dns-1.ct_ipv4_address, var.ipv4_subnet_cidr)
          ansible_port = 22
        },
      }
    }
  }
}

module "reconfigure_dns" { # this time add the hosts to the dns so we can use them for cert providing
  source = "./modules/playbook"
  depends_on = [
    module.configure_ca-1, # another host to make use of the host dns
  ]

  playbook          = "../ansible/dns-playbook.yml" # from root not module
  host_key_checking = "false"
  private_key_file  = local_sensitive_file.private_staging_key.filename
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    duckdns_domains  = var.duckdns_domains
    host_dns_enabled = true
  }
  inventory = {
    # all = {
    # children = {
    # "dns" = null
    # }
    # }
    dns = {
      hosts = {
        dns-1 = {
          ansible_host = trimsuffix(module.dns-1.ct_ipv4_address, var.ipv4_subnet_cidr)
        },
      }
    }
    ca = {
      hosts = {
        ca-1 = {
          ansible_host = trimsuffix(module.ca-1.ct_ipv4_address, var.ipv4_subnet_cidr)
        },
        wg-gw = {
          ansible_host = trimsuffix(module.wg_gw.ct_ipv4_address, var.ipv4_subnet_cidr)
        }
      }
    }
  }
}