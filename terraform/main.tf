module "control_plane" {
  source  = "./modules/k8/master"
  servers = ["master0"]

  ip_config = {
    ipv4_cidr    = var.ipv4_cidr
    ipv4_gateway = var.ipv4_gateway
    ipv4_subnet  = var.ipv4_subnet
    ipv6_subnet  = var.ipv6_subnet
    ipv6_cidr    = var.ipv6_cidr
    ipv6_gateway = var.ipv6_gateway
  }
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
}
module "data_plane" {
  source     = "./modules/k8/worker"
  depends_on = [module.control_plane]

  servers = ["worker0"]

  master_node_config = (local.master_node_config)
}


module "nfs_server" {
  source = "./modules/nfs"
  # allowed_addresses = ["192.168.0.24/32", "192.168.0.25/32"]

  usb_passthrough = {
    mapping = "storage"
    usb3    = true
    fstype  = "ext4"
  }
}
