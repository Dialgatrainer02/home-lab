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
  inventory = local.dns
}

module "reconfigure_dns" { # this time add the hosts to the dns so we can use them for cert providing
  source = "./modules/playbook"

  playbook          = "../ansible/dns-playbook.yml" # from root not module
  host_key_checking = "false"
  private_key_file  = local_sensitive_file.private_staging_key.filename
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    duckdns_domains  = var.duckdns_domains
    host_dns_enabled = true
  }
  inventory = merge(local.ca, local.dns, local.wireguard)
}

module "configure_ca-1" {
  source     = "./modules/playbook"

  playbook          = "../ansible/ca-playbook.yml"
  host_key_checking = "false"
  private_key_file  = local_sensitive_file.private_staging_key.filename
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    ca_name     = "staging-homelab"
    ca_password = var.pve_password
  }
  inventory = local.ca
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
  inventory = merge(local.dns, local.ca, )
}


module "wireguard" {
  source = "./modules/playbook"

  playbook = "../ansible/wg-playbook.yml"
  inventory = local.wireguard
  private_key_file = "./private_staging_key"
}

