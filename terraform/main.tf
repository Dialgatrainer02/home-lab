# module "load_balencers" {
  # source = "./modules/load_balancer"
# 
  # control_plane_nodes = local.haproxy_servers
# }
locals {
  control_plane_nodes = tolist(["master0"])
  haproxy_servers     = [for s in local.control_plane_nodes : "${local.ip_config.ipv4_subnet}.${index(local.control_plane_nodes, s) + 200}:6443"]
}

module "control_plane" {
  source  = "./modules/k8/master"
  servers = local.control_plane_nodes

  ip_config = merge(local.ip_config, { ipv4_start_range = 200 })
}


locals {
  master_name = keys(module.control_plane.private_keys)[0]
  master_node_config = {
    host             = module.control_plane.ip_addresses[local.master_name]
    name             = (local.master_name)
    private_key      = module.control_plane.private_keys[local.master_name]
    private_key_path = module.control_plane.private_key_paths[local.master_name]
    user             = "kubernetes"
  }

  nfs_config = {
    host               = module.nfs_server.ip_address
    server_mount_point = "/"
    client_mount_point = "/srv/shared"
  }

  ip_config = {
    ipv4_cidr    = var.ipv4_cidr
    ipv4_gateway = var.ipv4_gateway
    ipv4_subnet  = var.ipv4_subnet
    ipv6_subnet  = var.ipv6_subnet
    ipv6_cidr    = var.ipv6_cidr
    ipv6_gateway = var.ipv6_gateway
  }
}
module "data_plane" {
  source     = "./modules/k8/worker"
  depends_on = [module.control_plane]

  servers   = ["worker0", "worker1"]
  ip_config = merge(local.ip_config, { ipv4_start_range = 100 })

  master_node_config = (local.master_node_config)
  nfs_config         = (local.nfs_config)
}


module "nfs_server" {
  source = "./modules/nfs"
  # allowed_addresses = ["192.168.0.24/32", "192.168.0.25/32"]

  ip_config = local.ip_config
  usb_passthrough = {
    mapping = "storage"
    usb3    = true
    fstype  = "ext4"
  }
}
