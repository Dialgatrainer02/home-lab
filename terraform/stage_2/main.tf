module "minio" {
  source = "../modules/proxmox_ct"


  vm_id        = 200
  hostname     = "minio"
  description  = "minio s3 storage"
  ipv4_address = "${var.ipv4_subnet_net}.200${var.ipv4_subnet_cidr}"
  ipv4_gw      = var.ipv4_gw
  dns          = ["1.1.1.1", ]
  public_key   = var.public_key
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = var.ct_image
  host_vars = {
    acme_cert_name = "${module.minio.hostname}.${var.domain}"
    acme_cert_san  = [module.minio.ct_ipv4_address]
  }

  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}

module "mimir" {
  source = "../modules/proxmox_ct"


  vm_id        = 200
  hostname     = "mimir"
  description  = "mimir prometheus compatible database"
  ipv4_address = "${var.ipv4_subnet_net}.200${var.ipv4_subnet_cidr}"
  ipv4_gw      = var.ipv4_gw
  dns          = ["1.1.1.1", ]
  public_key   = var.public_key
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = var.ct_image
  host_vars = {
    acme_cert_name = "${module.mimir.hostname}.${var.domain}"
    acme_cert_san  = [module.mimir.ct_ipv4_address]
  }

  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}

module "loki" {
  source = "../modules/proxmox_ct"


  vm_id        = 200
  hostname     = "loki"
  description  = "loki logging database"
  ipv4_address = "${var.ipv4_subnet_net}.200${var.ipv4_subnet_cidr}"
  ipv4_gw      = var.ipv4_gw
  dns          = ["1.1.1.1", ]
  public_key   = var.public_key
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = var.ct_image
  host_vars = {
    acme_cert_name = "${module.loki.hostname}.${var.domain}"
    acme_cert_san  = [module.loki.ct_ipv4_address]
  }

  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}

module "grafana" {
  source = "../modules/proxmox_ct"


  vm_id        = 200
  hostname     = "grafana"
  description  = "grafana visulisation server"
  ipv4_address = "${var.ipv4_subnet_net}.200${var.ipv4_subnet_cidr}"
  ipv4_gw      = var.ipv4_gw
  dns          = ["1.1.1.1", ]
  public_key   = var.public_key
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = var.ct_image
  host_vars = {
    acme_cert_name = "${module.grafana.hostname}.${var.domain}"
    acme_cert_san  = [module.grafana.ct_ipv4_address]
  }

  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}

module "configure_stage_2" {
  source     = "./modules/playbook"

  playbook          = "../ansible/observability-playbook.yml"
  inventory         = merge(local.logging,var.alloy_hosts)
  host_key_checking = false
  private_key_file  = "./private_staging_key"
#   ansible_callback  = "default"
  quiet             = true
  extra_vars = {
    validate_certificate = true
    alias                = "mimir"
    minio_buckets = [
      {
        name   = "mimir-object"
        policy = "read-write"
      },
      {
        name   = "mimir-block"
        policy = "read-write"
      }
    ]
    minio_users = [
      {
        buckets_acl = [
          {
            name   = "mimir-object"
            policy = "read-write"
          },
          {
            name   = "mimir-block"
            policy = "read-write"
          }
        ]
        name     = "mimir"
        password = var.pve_password
      },
    ]
    minio_root_user     = "root"
    minio_root_password = var.pve_password
    minio_url           = "https://${local.dns_names.minio}:{{ server_port }}"
    minio_enable_tls    = true
    server_port         = "9091"
    object_storage = {
      storage = {

        backend = "s3"
        s3 = {
          endpoint          = local.dns_names.minio
          access_key_id     = "mimir"
          secret_access_key = "${var.pve_password}"
          insecure          = false # False when using https
          bucket_name       = "mimir-object"
        }
      }
      block_storage = {
        s3 = {
          bucket_name = "mimir-block"
        }
      }
    }
  }
}


