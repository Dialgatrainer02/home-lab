# proxmox_vm

makes a Virtual Machine using the bpg/proxmox provider then enables ssh

## example usage
```hcl
resource "proxmox_virtual_environment_download_file" "latest_almalinux_9-4_qcow2" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = local.node
  url          = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
  file_name    = "almalinux_9-4.img"
  overwrite_unmanaged = true
}

resource "tls_private_key" "staging_key" {
  algorithm = "ED25519"

}

variable "ipv4_subnet_pre" {
  type    = string
  default = "192.168.1"
}

variable "ipv4_subnet_cidr" {
  type    = string
  default = "/24"
}


module "test_vm" {
  source = "./modules/proxmox_vm"

  vm_id        = 102
  name         = "test-vm"
  description  = "test vm"
  ipv4_address = "${var.ipv4_subnet_pre}.102${var.ipv4_subnet_cidr}" # becomes 192.168.0.102/24
  ipv4_gw      = "192.168.0.1"
  dns          = ["1.1.1.1", "1.0.0.1"]
  public_key   = trimspace(tls_private_key.staging_key.public_key_openssh)
  username     = "almalinux"
  cores        = 2
  disk_size    = "20"
  mem_size     = "2048"
  os_image     = proxmox_virtual_environment_download_file.latest_almalinux_9-4_qcow2.id
  os_image_type= "qcow2"
  agent        = true
}
```