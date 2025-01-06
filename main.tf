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
    inventory = merge(module.dns_1.service_inventory, module.dns_0.service_inventory)
    addrs     = [module.dns_1.service_ipv4_address, module.dns_0.service_ipv4_address]
  }
}
module "dns_0" {
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
      prom = "http://mimir-1.internal:8080/api/v1/push"
      loki = "http://loki-1.internal:3100/loki/api/v1/push"
    }
  }

  acme_cert = {
    provision = false
  }
  dns = {
    entry = false
    host  = local.dns_servers.inventory
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


module "dns_1" {
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
        step_acme_cert_name          = "dns-1.internal"
        step_acme_cert_san           = ["${var.ipv4_network_bits}.201"]
      }
    }
  }
  alloy = {
    install = true
    endpoints = {
      prom = "http://mimir-1.internal:8080/api/v1/push"
      loki = "http://loki-1.internal:3100/loki/api/v1/push"
    }
  }
  acme_cert = {
    provision = false
    config = { # example config
      ca_url  = "https://step-1.internal"
      ca_host = module.step_1.service_inventory
    }
  }

  dns = {
    entry = false
    host  = local.dns_servers.inventory
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



module "step_1" {
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
      host_vars = {
        ansible_ssh_private_key_file = ".keys/step-1_private_key"
      }
    }
  }
  alloy = {
    install = true
    endpoints = {
      prom = "http://mimir-1.internal:8080/api/v1/push"
      loki = "http://loki-1.internal:3100/loki/api/v1/push"
    }
  }

  acme_cert = {
    provision = false
    # config = { # example config
    # ca_url = "https://step_1.internal"  
    # ca_host = module.step_1.service_inventory
    # }
  }
  dns = {
    entry = true
    host  = local.dns_servers.inventory
  }
  service_vars = {
    step_ca_name                  = "homelab inc"
    step_ca_root_password         = var.pve_password
    step_ca_intermediate_password = var.pve_password
  }
}



# module "wireguard" {
# source = "./modules/oracle/compute"
# 
# oci_settings = {
# compartment_ocid = var.compartment_ocid
# region           = var.region
# user_ocid        = var.user_ocid
# fingerprint      = var.fingerprint
# oci_private_key  = var.oci_private_key
# tenancy_ocid     = var.tenancy_ocid
# }
# 
# compute = {
# egress_rules = [{
# tcp_options = {}
# udp_options = {}
# }]
# ingress_rules = [{
# tcp_options = {}
# udp_options = {}
# }]
# }
# 
# }


module "minio_1" {
  source     = "./modules/service_ct"
  depends_on = [module.step_1]

  pve_settings = local.pve_settings
  service = {
    service_name        = "minio-1"
    service_type        = "minio"
    service_description = "minio s3 compatible storage 1"
    service_os_image    = proxmox_virtual_environment_download_file.release_almalinux_9_4_lxc_img.id
    service_os_type     = "centos"
    service_ipv4 = {
      ipv4_address = "${var.ipv4_network_bits}.203${var.ipv4_cidr}"
      ipv4_gateway = var.ipv4_gateway
    }
    custom_ct = {
      startup = true
      cores   = 2
      dns     = local.dns_servers.addrs
      memory  = 2048
      disk    = "10"

      host_vars = {
        ansible_ssh_private_key_file = ".keys/minio-1_private_key"
        step_acme_cert_name          = "minio-1.internal"
        step_acme_cert_san           = ["${var.ipv4_network_bits}.203"]
      }
    }
  }
  alloy = {
    install = true
    endpoints = {
      prom = "http://mimir-1.internal:8080/api/v1/push"
      loki = "http://loki-1.internal:3100/loki/api/v1/push"
    }
  }

  acme_cert = {
    provision = true
    config = { # example config
      ca_url  = "https://step_1.internal"
      ca_host = module.step_1.service_inventory
    }
  }
  dns = {
    entry = true
    host  = local.dns_servers.inventory
  }
  service_vars = {
    validate_certificate = true
    minio_alias          = "logging"
    minio_buckets = [
      {
        name   = "mimir-block"
        policy = "read-write"
      },
      {
        name   = "mimir-alert"
        policy = "read-write"
      },
      {
        name   = "mimir-ruler"
        policy = "read-write"
      },
      {
        name   = "loki-chunk"
        policy = "read-write"
      }
    ]
    minio_users = [
      {
        buckets_acl = [
          {
            name   = "mimir-block"
            policy = "read-write"
          },
          {
            name   = "mimir-alert"
            policy = "read-write"
          },
          {
            name   = "mimir-ruler"
            policy = "read-write"
          },
        ]
        name     = "mimir"
        password = var.pve_password
      },
      {
        buckets_acl = [
          {
            name   = "loki-chunk"
            policy = "read-write"
          }
        ]
        name     = "loki"
        password = var.pve_password
      }
    ]
    minio_root_user               = "root"
    minio_root_password           = var.pve_password
    minio_url                     = "https://minio-1.internal:{{ server_port }}"
    minio_enable_tls              = true
    minio_prometheus_bearer_token = true
    server_port                   = "9091"

  }
}


module "loki_1" {
  source = "./modules/service_ct"
  depends_on = [module.step_1,
  module.minio_1, ] # needs step ca for acme certs

  pve_settings = local.pve_settings
  service = {
    service_name        = "loki-1"
    service_type        = "loki"
    service_description = "grafana loki server 1"
    service_os_image    = proxmox_virtual_environment_download_file.release_almalinux_9_4_lxc_img.id
    service_os_type     = "centos"
    service_ipv4 = {
      ipv4_address = "${var.ipv4_network_bits}.204${var.ipv4_cidr}"
      ipv4_gateway = var.ipv4_gateway
    }
    custom_ct = {
      startup = true
      cores   = 1
      dns     = local.dns_servers.addrs
      host_vars = {
        ansible_ssh_private_key_file = ".keys/loki-1_private_key"
        step_acme_cert_name          = "loki-1.internal"
        step_acme_cert_san           = ["${var.ipv4_network_bits}.204"]
      }
    }
  }
  alloy = {
    install = true
    endpoints = {
      prom = "http://mimir-1.internal:8080/api/v1/push"
      loki = "http://loki-1.internal:3100/loki/api/v1/push"
    }
  }

  acme_cert = {
    provision = true
    config = { # example config
      ca_url  = "https://step_1.internal"
      ca_host = module.step_1.service_inventory
    }
  }
  dns = {
    entry = true
    host  = local.dns_servers.inventory
  }
  service_vars = {

    loki_auth_enabled = false
    loki_common = {
      path_prefix        = "{{ loki_working_path }}"
      replication_factor = 1
      ring = {
        instance_addr = "127.0.0.1"
        kvstore = {
          store = "inmemory"
        }
      }
    }
    loki_schema_config = {
      configs = [
        {
          from = "2025-01-05"
          index = {
            period = "24h"
            prefix = "index_"
          }
          object_store = "s3"
          schema       = "v13"
          store        = "tsdb"
        },
      ]
    }
    loki_server = {
      http_listen_port = 3100
      # http_tls_config = {
      # cert = "/etc/ssl/step.crt"
      # key = "/etc/ssl/step.key"
      # }
      # grpc_tls_config = {
      # cert = "/etc/ssl/step.crt"
      # key = "/etc/ssl/step.key"
      # }
    }
    loki_storage_config = {
      aws = {
        insecure         = false
        s3               = "https://loki:${var.pve_password}@minio-1.internal:9091/loki-chunk"
        s3forcepathstyle = true
      }
      tsdb_shipper = {
        active_index_directory = "{{ loki_working_path }}/loki/index"
        cache_location         = "{{ loki_working_path }}/loki/index_cache"
      }
    }
  }
}

module "mimir_1" {
  source = "./modules/service_ct"
  depends_on = [module.step_1,
  module.minio_1] # needs step ca for acme certs

  pve_settings = local.pve_settings
  service = {
    service_name        = "mimir-1"
    service_type        = "mimir"
    service_description = "grafana mimir server 1"
    service_os_image    = proxmox_virtual_environment_download_file.release_almalinux_9_4_lxc_img.id
    service_os_type     = "centos"
    service_ipv4 = {
      ipv4_address = "${var.ipv4_network_bits}.205${var.ipv4_cidr}"
      ipv4_gateway = var.ipv4_gateway
    }
    custom_ct = {
      startup = true
      cores   = 2
      dns     = local.dns_servers.addrs
      memory  = 2048
      host_vars = {
        ansible_ssh_private_key_file = ".keys/mimir-1_private_key"
        step_acme_cert_name          = "mimir-1.internal"
        step_acme_cert_san           = ["${var.ipv4_network_bits}.205"]
      }
    }
  }
  alloy = {
    install = true
    endpoints = {
      prom = "http://mimir-1.internal:8080/api/v1/push"
      loki = "http://loki-1.internal:3100/loki/api/v1/push"
    }
  }

  acme_cert = {
    provision = true
    config = { # example config
      ca_url  = "https://step_1.internal"
      ca_host = module.step_1.service_inventory
    }
  }
  dns = {
    entry = true
    host  = local.dns_servers.inventory
  }
  service_vars = {

    mimir_server = {
      http_listen_port = 8080
      # http_tls_config = {
      # cert = "/etc/ssl/step.crt"
      # key  = "/etc/ssl/step.key"
      # }
      # grpc_tls_config = {
      # cert = "/etc/ssl/step.crt"
      # key  = "/etc/ssl/step.key"
      # }
    }
    mimir_storage = {
      storage = {
        backend = "s3"
        s3 = {
          endpoint          = "minio-1.internal:9091"
          access_key_id     = "mimir"
          secret_access_key = var.pve_password
          insecure          = false
        }
      }
    }

    # Blocks storage requires a prefix when using a common object storage bucket.
    mimir_blocks_storage = {
      s3 = {
        bucket_name = "mimir-block"
      }
    }
    mimir_alertmanager_storage = {
      s3 = {
        bucket_name = "mimir-alert"
      }
    }
    mimir_ruler_storage = {
      s3 = {
        bucket_name = "mimir-ruler"
      }
    }
  }
}
