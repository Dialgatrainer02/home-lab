module "ca-1" {
  source = "${path.root}/modules/proxmox_ct"
  # depends_on = [ module.configure_dns ]


  vm_id        = 200
  hostname     = "ca-1"
  description  = "Step ca server"
  ipv4_address = "${var.ipv4_subnet_pre}.200${var.ipv4_subnet_cidr}"
  ipv4_gw      = "192.168.0.1"
  dns          = ["${trimsuffix(module.dns-1.ct_ipv4_address, "/24")}"]
  public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}

module "configure_ca-1" {
  source     = "./modules/playbook"
  depends_on = [module.ca-1, ]

  playbook          = "../ansible/ca-playbook.yml"
  host_key_checking = "false"
  private_key_file  = local_sensitive_file.private_staging_key.filename
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    ca_name     = "staging-homelab"
    ca_password = var.pve_password
  }
  inventory = {
    all = {
      children = {
        "ca" = null
      }
    }
    ca = {
      hosts = {
        ca-1 = {
          ansible_host = trimsuffix(module.ca-1.ct_ipv4_address, var.ipv4_subnet_cidr)
          ansible_port = 22
        },
      }
    }
  }
}


module "acme_certs" {
  source = "./modules/playbook"
  depends_on = [
    module.reconfigure_dns, # requires dns names
    module.configure_ca-1   # requires working ca
  ]

  playbook          = "../ansible/cert-playbook.yml"
  host_key_checking = "false"
  private_key_file  = local_sensitive_file.private_staging_key.filename
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    ca_url = "${trimsuffix(module.ca-1.ct_ipv4_address, var.ipv4_subnet_cidr)}"
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
          ansible_host   = trimsuffix(module.dns-1.ct_ipv4_address, var.ipv4_subnet_cidr)
          acme_cert_name = "dns-1.dialgatrainer.duckdns.org"
          acme_cert_san  = ["${trimsuffix(module.dns-1.ct_ipv4_address, var.ipv4_subnet_cidr)}"]
        },
      }
    }
    ca = {
      hosts = {
        ca-1 = {
          ansible_host   = trimsuffix(module.ca-1.ct_ipv4_address, var.ipv4_subnet_cidr)
          acme_cert_name = "ca-1.dialgatrainer.duckdns.org"
          acme_cert_san  = ["${trimsuffix(module.ca-1.ct_ipv4_address, var.ipv4_subnet_cidr)}"]
        },
      }
    }
  }
}