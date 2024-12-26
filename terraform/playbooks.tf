module "configure_dns" {
  source     = "./modules/playbook"
  depends_on = [module.dns-1]

  playbook          = "../ansible/dns-playbook.yml" # from root not module
  host_key_checking = "false"
  private_key_file  = local_sensitive_file.private_staging_key.filename
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    custom_dns = {
      "${local.dns_names.ca-1}"  = module.ca-1.ct_ipv4_address
      "${local.dns_names.dns-1}" = module.dns-1.ct_ipv4_address
      "${local.dns_names.wg_gw}" = module.wg_gw.ct_ipv4_address
      "${local.dns_names.minio}" = module.minio.ct_ipv4_address
    }
  }
  inventory = local.dns
}


module "configure_ca-1" {
  source     = "./modules/playbook"
  depends_on = [module.ca-1]

  playbook          = "../ansible/ca-playbook.yml"
  host_key_checking = "false"
  private_key_file  = local_sensitive_file.private_staging_key.filename
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    ca_name     = "staging-homelab"
    ca_password = var.pve_password
    ca_ssh      = false
  }
  inventory = local.ca
}


module "acme_certs" {
  source = "./modules/playbook"
  depends_on = [
    module.configure_dns,  # requires dns names
    module.configure_ca-1, # requires working ca
    module.minio
  ]

  playbook          = "../ansible/cert-playbook.yml"
  host_key_checking = "false"
  private_key_file  = local_sensitive_file.private_staging_key.filename
  ssh_user          = "root"
  quiet             = true
  extra_vars = {
    ca_url = "https://${module.ca-1.ct_ipv4_address}"
  }
  inventory = merge(local.dns, local.ca, local.logging)
}


module "wireguard" {
  source = "./modules/playbook"

  playbook         = "../ansible/wg-playbook.yml"
  inventory        = local.wireguard
  private_key_file = "./private_staging_key"
}


module "configure_minio" {
  source     = "./modules/playbook"
  depends_on = [module.acme_certs]

  playbook         = "../ansible/observability-playbook.yml"
  inventory        = local.logging
  private_key_file = "./private_staging_key"
  ansible_callback = "default"
  quiet            = true
  extra_vars = {
    validate_certificate = true
    alias = "mimir"
    minio_buckets = [
      {
        name   = "mimir"
        policy = "read-write"
      },
    ]
    minio_users = [
      {
        buckets_acl = [
          {
            name   = "mimir"
            policy = "read-write"
          },
        ]
        name     = "mimir"
        password = var.pve_password
      },
    ]
    minio_root_user     = "root"
    minio_root_password = var.pve_password
    minio_url           = "https://${local.dns_names.minio}:{{ server_port }}"
    minio_enable_tls    = true
    server_port = "9091"
  }

}
locals {
  dns_names = {
    minio = "${module.minio.hostname}.${local.domain}"
    ca-1  = "${module.ca-1.hostname}.${local.domain}"
    dns-1 = "${module.dns-1.hostname}.${local.domain}"
    wg_gw = "${module.wg_gw.hostname}.${local.domain}"
  }
}

