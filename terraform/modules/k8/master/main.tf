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

resource "local_sensitive_file" "master_ssh_config" {
  filename = "${path.root}/secrets/master_ssh_config"

  content = templatefile("${path.module}/templates/ssh_config.tftpl", merge(local.server_ssh_config, { provision_user : (var.provision_user) }))

}

locals {
  server_ssh_config = { servers = { for s in var.servers : s => {
    ip_address = proxmox_virtual_environment_vm.master[s].ipv4_addresses[1][0]
    id_file    = local_sensitive_file.private_key[s].filename
  } } }
}

resource "random_integer" "vm_id" {
  for_each = (local.servers)
  min      = 100
  max      = 200
}

resource "proxmox_virtual_environment_vm" "master" {
  for_each = local.servers

  node_name = (local.node)
  vm_id     = (random_integer.vm_id[each.value].result)
  name      = (each.value)
  tags      = ["almalinux", "k8", "master", "terraform"]

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
      keys     = [trimspace(tls_private_key.ssh[each.value].public_key_openssh)]
    }
  }

  connection {
    type        = "ssh"
    host        = (self.ipv4_addresses[1][0])
    user        = (var.provision_user)
    private_key = (trimspace(tls_private_key.ssh[each.value].private_key_openssh))
  }
}

locals {
  leader      = (one(slice(var.servers, 0, 1)))
  leader_ip   = (proxmox_virtual_environment_vm.master[local.leader].ipv4_addresses[1][0])
  non_leaders = (slice(var.servers, 1, length(var.servers)))
}

resource "terraform_data" "kubernetes_control_plane_init" {
  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.master]
  }
  connection {
    host        = (local.leader_ip)
    private_key = (trimspace(tls_private_key.ssh[local.leader].private_key_openssh))
    user        = (var.provision_user)
  }

  provisioner "file" {
    destination = "/tmp/kube-flannel.yml"
    source      = "${path.module}/files/kube-flannel.yml"

  }
  provisioner "remote-exec" { # cluster init
    inline = ["sudo kubeadm init --upload-certs --control-plane-endpoint=${local.leader_ip} --pod-network-cidr=10.244.0.0/16",
      "echo $(sudo kubeadm token create --print-join-command) --control-plane --certificate-key $(sudo kubeadm init phase upload-certs --upload-certs | grep -vw -e certificate -e Namespace) | tee /tmp/control-plane-join.sh",
      "KUBECONFIG=/etc/kubernetes/admin.conf sudo -E kubectl apply -f /tmp/kube-flannel.yml",
      "KUBECONFIG=/etc/kubernetes/admin.conf sudo -E kubectl apply -f  https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml",
      "mkdir -p $HOME/.kube", # put in kubectl_setup later once its working properly
      "sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
    ]
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.root}/secrets/.kube/ && scp -F ${local_sensitive_file.master_ssh_config.filename} ${local.leader}:/home/${var.provision_user}/.kube/config ${path.root}/secrets/.kube/config"
  }

  provisioner "remote-exec" {
    inline = ["sudo systemctl restart sshd"]
  }
}


resource "terraform_data" "kubernetes_control_plane_join" {
  for_each = (toset(local.non_leaders))
  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.master]
  }
  depends_on = [terraform_data.kubernetes_control_plane_init]
  connection {
    host        = (proxmox_virtual_environment_vm.master[each.value].ipv4_addresses[1][0])
    private_key = (trimspace(tls_private_key.ssh[each.value].private_key_openssh))
    user        = (var.provision_user)
  }

  provisioner "local-exec" {
    command = "scp -F ${local_sensitive_file.master_ssh_config.filename} ${local.leader}:/tmp/control-plane-join.sh ${each.value}:/tmp/control-plane-join.sh"
  }
  provisioner "remote-exec" {
    inline = ["sudo chmod +x /tmp/control-plane-join.sh",
      "sudo bash /tmp/control-plane-join.sh",
      "mkdir -p $HOME/.kube",
      "sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
    ]
  }
}

# resource "terraform_data" "kubectl_setup" {
# for_each = local.servers
# lifecycle {
# replace_triggered_by = [ proxmox_virtual_environment_vm.master ]
# }
# depends_on = [ terraform_data.kubernetes_control_plane_init ]
# connection {
# host = proxmox_virtual_environment_vm.master[each.value].ipv4_addresses[1][0]
# private_key = trimspace(tls_private_key.ssh[each.value].private_key_openssh)
# user = "${var.provision_user}"
# }
# provisioner "remote-exec" {
# inline = [ "mkdir -p $HOME/.kube",
# "sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config",
# "sudo chown $(id -u):$(id -g) $HOME/.kube/config", 
# ]
# }
# }