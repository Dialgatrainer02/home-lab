resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "random_integer" "vm_id" {
  min = 100
  max = 800
}

resource "local_sensitive_file" "private_key" {
  filename = "${path.root}/secrets/keys/${var.vm_name}-key"
  content  = (tls_private_key.ssh.private_key_openssh)
}

resource "local_sensitive_file" "nfs_ssh_config" {
  filename = "${path.root}/secrets/nfs_ssh_config"

  content = templatefile("${path.module}/templates/ssh_config.tftpl", merge(local.server_ssh_config, { provision_user : (var.provision_user) }))

}

locals {
  server_ssh_config = { server = {
    name       = (var.vm_name)
    ip_address = (proxmox_virtual_environment_vm.nfs_server.ipv4_addresses[1][0])
    id_file    = (local_sensitive_file.private_key.filename)
  } }
}

resource "proxmox_virtual_environment_vm" "nfs_server" {


  node_name = (local.node)
  vm_id     = (random_integer.vm_id.result)
  name      = (var.vm_name)
  tags      = ["almalinux", "nfs", "terraform"]

  bios    = "ovmf"
  machine = "q35"
  clone {
    vm_id        = 902
    datastore_id = (local.datastore_id)
  }

  usb {
    host    = (var.usb_passthrough.host)
    mapping = (var.usb_passthrough.mapping)
    usb3    = (var.usb_passthrough.usb3)
  }

  initialization {
    datastore_id = (local.datastore_id)

    ip_config {
      ipv4 {
        address = "${var.ip_config.ipv4_subnet}.150${var.ip_config.ipv4_cidr}"
        gateway = (var.ip_config.ipv4_gateway)
      }
    }
    user_account {
      username = (var.provision_user)
      keys     = [(trimspace(tls_private_key.ssh.public_key_openssh))]
    }
  }

  connection {
    type        = "ssh"
    host        = (self.ipv4_addresses[1][0])
    user        = (var.provision_user)
    private_key = (trimspace(tls_private_key.ssh.private_key_openssh))
  }

  provisioner "remote-exec" {
    # count = var.usb_passthrough != null ? 1 : 0
    inline = [
      "sudo mkdir -p ${var.nfs_mount_points[0]}",
      "echo '/dev/sdb1 ${var.nfs_mount_points[0]} ${var.usb_passthrough.fstype} defaults 0 0' | sudo tee -a /etc/fstab",
      "sudo systemctl daemon-reload",
      "sudo mount /dev/sdb1 ${var.nfs_mount_points[0]}"
    ]

  }

  provisioner "remote-exec" {
    inline = [
      "echo '${templatefile("${path.module}/templates/exports.tftpl", local.export_server_config)}' | sudo tee /etc/exports",
      "sudo exportfs -arv"
    ]
  }
}

locals {
  export_server_config = {mount_points: (var.nfs_mount_points), allowed_addresses: (var.allowed_addresses) }
}