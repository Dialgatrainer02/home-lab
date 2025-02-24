module "control_plane" {
  source  = "./modules/k8/master"
  servers = ["master0"]
}


locals {
  master_node_config = {
    host        = "${module.control_plane.ip_addresses[keys(module.control_plane.ip_addresses)[0]]}"
    name        = "${keys(module.control_plane.private_keys)[0]}"
    private_key = "${module.control_plane.private_keys[keys(module.control_plane.private_keys)[0]]}"
    user        = "kubernetes"
  }
}
module "data_plane" {
  source     = "./modules/k8/worker"
  depends_on = [module.control_plane]

  master_node_config = local.master_node_config
}


# module "nfs_server" {
# source = "./modules/nfs"
# allowed_addresses = ["192.168.0.24/32", "192.168.0.25/32"]
# 
# usb_passthrough = {
# mapping = "storage"
# usb3 = true
# fstype = "ext4"
# }
# }
# 