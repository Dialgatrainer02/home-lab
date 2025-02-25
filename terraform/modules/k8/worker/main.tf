locals {
  servers = toset(var.servers)
}

resource "tls_private_key" "ssh" {
  for_each  = (local.servers)
  algorithm = "ED25519"
}

resource "local_sensitive_file" "private_key" {
  for_each = (local.servers)
  filename = "${path.root}/secrets/keys/${each.value}-key"
  content  = (tls_private_key.ssh[each.value].private_key_openssh)
}

resource "local_sensitive_file" "worker_ssh_config" {
  filename = "${path.root}/secrets/worker_ssh_config"

  content = templatefile("${path.module}/templates/ssh_config.tftpl", merge(local.server_ssh_config, { provision_user : (var.provision_user) }))

}

locals {
  server_ssh_config = { servers = { for s in var.servers : s => {
    ip_address = (proxmox_virtual_environment_vm.worker[s].ipv4_addresses[1][0])
    id_file    = (local_sensitive_file.private_key[s].filename)
  } } }
}


resource "random_integer" "vm_id" {
  for_each = (local.servers)
  min      = 200
  max      = 300
}

resource "proxmox_virtual_environment_vm" "worker" {
  for_each = (local.servers)


  node_name = (local.node)
  vm_id     = (random_integer.vm_id[each.value].result)
  name      = (each.value)
  tags      = ["almalinux", "k8", "worker", "terraform"]

  bios    = "ovmf"
  machine = "q35"
  clone {
    vm_id        = 900
    datastore_id = (local.datastore_id)
  }

  initialization {
    datastore_id = (local.datastore_id)

    ip_config {
      ipv4 {
        address = "${var.ip_config.ipv4_subnet}.${index(var.servers, each.value) + (var.ip_config.ipv4_start_range)}${var.ip_config.ipv4_cidr}"
        gateway = (var.ip_config.ipv4_gateway)
      }
    }
    user_account {
      username = (var.provision_user)
      keys     = [(trimspace(tls_private_key.ssh[each.value].public_key_openssh))]
    }
  }

  connection {
    type        = "ssh"
    host        = (self.ipv4_addresses[1][0])
    user        = (var.provision_user)
    private_key = (trimspace(tls_private_key.ssh[each.value].private_key_openssh))
  }

}
resource "terraform_data" "master_join" {
  for_each         = (local.servers)
  depends_on       = [proxmox_virtual_environment_vm.worker]
  triggers_replace = (var.master_node_config)
  connection {
    host        = (var.master_node_config.host)
    private_key = (var.master_node_config.private_key)
    user        = (var.master_node_config.user)
  }

  provisioner "remote-exec" {
    inline = ["sudo kubeadm token create --print-join-command | tee /tmp/worker-join.sh", ]
  }

  provisioner "local-exec" {
    connection {
      host        = (proxmox_virtual_environment_vm.worker[each.value].ipv4_addresses[1][0])
      user        = (var.provision_user)
      private_key = (trimspace(tls_private_key.ssh[each.value].private_key_openssh))
    } # make sure the worker node is ready to connect
    command = "scp -o StrictHostKeyChecking=no -i ${var.master_node_config.private_key_path} -F ${local_sensitive_file.worker_ssh_config.filename} ${var.master_node_config.user}@${var.master_node_config.host}:/tmp/worker-join.sh ${each.value}:/tmp/worker-join.sh"
  }
  provisioner "remote-exec" {

    connection {
      host        = (proxmox_virtual_environment_vm.worker[each.value].ipv4_addresses[1][0])
      user        = (var.provision_user)
      private_key = (trimspace(tls_private_key.ssh[each.value].private_key_openssh))
    }

    inline = ["sudo bash /tmp/worker-join.sh"]
  }
}

resource "terraform_data" "nfs_setup" {
  for_each = (local.servers)
  connection {
    host        = (proxmox_virtual_environment_vm.worker[each.value].ipv4_addresses[1][0])
    user        = (var.provision_user)
    private_key = (trimspace(tls_private_key.ssh[each.value].private_key_openssh))
  }

  provisioner "remote-exec" {
    inline = ["sudo mkdir -p ${var.nfs_config.client_mount_point}",
      "echo '${var.nfs_config.host}:${var.nfs_config.server_mount_point}  ${var.nfs_config.client_mount_point} nfs defaults,user,noexec,nosuid,timeo=900,retrans=5,_netdev	0 0' | sudo tee -a /etc/fstab",
      "sudo systemctl daemon-reload",
      "mount '${var.nfs_config.host}:${var.nfs_config.server_mount_point}'"
    ]

  }
}