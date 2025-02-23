# module "control_plane" {
  # source = "./modules/k8/master"
# 
# }

# module "data_plane" {
  # source = "./modules/k8/worker"
# 
# }

module "nfs_server" {
  source = "./modules/nfs"
  # allowed_addresses = ["192.168.0.24/32", "192.168.0.25/32"]

  usb_passthrough = {
    mapping = "storage"
    usb3 = true
  }
}