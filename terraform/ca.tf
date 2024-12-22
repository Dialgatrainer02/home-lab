module "Step_ca" {
  source       = "${path.root}/modules/proxmox_ct"
  vm_id        = 200
  hostname     = "step-ca"
  description  = "Step ca server"
  ipv4_address = "${var.ipv4_subnet_pre}.200${var.ipv4_subnet_cidr}"
  ipv4_gw      = "192.168.0.1"
  dns          = ["1.1.1.1", "1.0.0.1"]
  public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
  cores        = 1
  disk_size    = "5"
  mem_size     = "1024"
  os_image     = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
  pve_address  = var.pve_address
  pve_password = var.pve_password
  pve_username = var.pve_username
}

module "configure_step_ca" {
  source = "./modules/configure"

  playbook = "../ansible/stepCA-playbook.yml" # from root not module
  host_key_checking = "acept-new"
  private_key_file = local_sensitive_file.private_staging_key.filename
  ssh_user = "root"
  quiet = true
  # extra_vars = {
    # test = "testing"
  # }
  inventory = {
    all = {
      children = {
        "ca" = null
      }
      }
    ca = {
      hosts = {
        step_ca = {
          ansible_host = trimsuffix(module.Step_ca.ct_ipv4_address, var.ipv4_subnet_cidr)
          ansible_port = 22
        },
      }
    }
  }
}