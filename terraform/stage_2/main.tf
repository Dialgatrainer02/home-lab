module "minio" {
  source = "${path.root}/modules/proxmox_ct"


  vm_id        = 203
  hostname     = "minio"
  description  = "s3 compatible block storage"
  ipv4_address = "${var.ipv4_subnet_pre}.203${var.ipv4_subnet_cidr}"
  ipv4_gw      = "192.168.0.1"
  dns          = [module.dns-1.ct_ipv4_address]
  public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
  cores        = 1
  disk_size    = "10"
  mem_size     = "1024"
  os_image     = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
  host_vars = {
    acme_cert_name = "${local.dns_names.minio}"
    acme_cert_san  = [module.minio.ct_ipv4_address]
  }

  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}

module "mimir" {
  source = "${path.root}/modules/proxmox_ct"


  vm_id        = 204
  hostname     = "mimir"
  description  = "grafana mimir "
  ipv4_address = "${var.ipv4_subnet_pre}.204${var.ipv4_subnet_cidr}"
  ipv4_gw      = "192.168.0.1"
  dns          = [module.dns-1.ct_ipv4_address]
  public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
  cores        = 1
  disk_size    = "10"
  mem_size     = "1024"
  os_image     = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
  host_vars = {
    acme_cert_name = "${local.dns_names.mimir}"
    acme_cert_san  = [module.mimir.ct_ipv4_address]
  }

  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}


module "configure_mimir" {
  source     = "./modules/playbook"
  depends_on = [module.acme_certs]

  playbook          = "../ansible/observability-playbook.yml"
  inventory         = local.logging
  host_key_checking = false
  private_key_file  = "./private_staging_key"
  ansible_callback  = "default"
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


