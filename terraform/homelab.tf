terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${var.pve_address}:8006"

  username = var.pve_username
  password = var.pve_password
  insecure = true
  tmp_dir  = "/tmp"
}

provider "oci" {
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}




resource "proxmox_virtual_environment_download_file" "release_almalinux_9-4_lxc_img" {
  connection {
    host     = "192.168.0.90"
    type     = "ssh"
    user     = "root"
    password = var.pve_password
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /mnt/bindmounts/terraform"
    ]
  }
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "pve"
  url          = "http://download.proxmox.com/images/system/almalinux-9-default_20240911_amd64.tar.xz"
}

resource "proxmox_virtual_environment_download_file" "latest_almalinux_9-4_qcow2" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  url          = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-9.4-20240507.x86_64.qcow2"
  file_name    = "almalinux_9-4.img"
}

resource "proxmox_virtual_environment_container" "almalinux_dns" {
  for_each = var.dns_servers

  description = "Managed by Terraform"

  started   = true
  node_name = local.node
  vm_id     = var.dns_servers[each.key].id + 200

  unprivileged = true

  initialization {
    hostname = each.key

    ip_config {
      ipv4 {
        address = "192.168.0.${var.dns_servers[each.key].id + 200}/24"
        gateway = "192.168.0.1"
      }
    }
    dns {
      servers = ["1.1.1.1", "1.0.0.1"]
    }

    user_account {
      keys = [
        trimspace(tls_private_key.homelab_key.public_key_openssh)
      ]
    }
  }
  cpu {
    cores = "2"
  }

  disk {
    datastore_id = local.datastore_id
    size         = 4
  }
  memory {
    dedicated = "2048"
    swap      = "1024"
  }

  network_interface {
    name = "veth0"
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type = "centos"
  }
  start_on_boot = "true"

  connection {
    host     = var.pve_address
    type     = "ssh"
    user     = "root"
    password = var.pve_password
  }
  provisioner "file" {
    source      = "./enable_ssh.sh"
    destination = "/mnt/bindmounts/terraform/enable_ssh.sh"

  }

  provisioner "remote-exec" {
    inline = [
      "pct exec ${var.dns_servers[each.key].id + 200} bash /terraform/enable_ssh.sh"
    ]
  }
  mount_point {
    volume = "/mnt/bindmounts/terraform"
    path   = "/terraform"
    shared = "true"
  }
}

resource "terraform_data" "ansible_dns" {
  input = proxmox_virtual_environment_container.almalinux_dns["dns2"].vm_id
  provisioner "local-exec" {
    command     = "ansible-playbook ./playbook.yml -t bootstrap -i ./terraform/${local_file.bootstrap.filename} --ssh-extra-args '-o StrictHostKeyChecking=false'"
    working_dir = "../"
  }
}

resource "proxmox_virtual_environment_container" "almalinux_container" {
  for_each = var.containers

  description = "Managed by Terraform"

  started   = true
  node_name = local.node
  vm_id     = var.containers[each.key].id + 200

  unprivileged = true

  initialization {
    hostname = each.key

    ip_config {
      ipv4 {
        address = "192.168.0.${var.containers[each.key].id + 200}/24"
        gateway = "192.168.0.1"
      }
    }
    dns {
      servers = ["${trimsuffix(proxmox_virtual_environment_container.almalinux_dns["dns1"].initialization[0].ip_config[0].ipv4[0].address, "/24")}", "${trimsuffix(proxmox_virtual_environment_container.almalinux_dns["dns2"].initialization[0].ip_config[0].ipv4[0].address, "/24")}"]
    }
    # dns {
    # servers = ["1.1.1.1", "1.0.0.1"]
    # }

    user_account {
      keys = [
        trimspace(tls_private_key.homelab_key.public_key_openssh)
      ]
    }
  }
  cpu {
    cores = "2"
  }

  disk {
    datastore_id = local.datastore_id
    size         = 4
  }
  memory {
    dedicated = "2048"
    swap      = "1024"
  }

  network_interface {
    name = "veth0"
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.release_almalinux_9-4_lxc_img.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type = "centos"
  }
  start_on_boot = "true"

  connection {
    host     = var.pve_address
    type     = "ssh"
    user     = "root"
    password = var.pve_password
  }
  provisioner "file" {
    source      = "./enable_ssh.sh"
    destination = "/mnt/bindmounts/terraform/enable_ssh.sh"

  }

  provisioner "remote-exec" {
    inline = [
      "pct exec ${var.containers[each.key].id + 200} bash /terraform/enable_ssh.sh"
    ]
  }
  mount_point {
    volume = "/mnt/bindmounts/terraform"
    path   = "/terraform"
    shared = "true"
  }
}

resource "proxmox_virtual_environment_vm" "almalinux_vm" {
  for_each = var.vms

  name      = each.key
  node_name = local.node
  vm_id     = var.vms[each.key].id + 100

  started = "true"
  on_boot = "true"
  bios    = "ovmf"
  machine = "q35"


  agent {
    enabled = true
  }

  initialization {
    datastore_id = local.datastore_id
    ip_config {
      ipv4 {
        address = "192.168.0.${var.vms[each.key].id + 100}/24"
        gateway = "192.168.0.1"
      }
    }
    dns {
      servers = ["${trimsuffix(proxmox_virtual_environment_container.almalinux_dns["dns1"].initialization[0].ip_config[0].ipv4[0].address, "/24")}", "${trimsuffix(proxmox_virtual_environment_container.almalinux_dns["dns2"].initialization[0].ip_config[0].ipv4[0].address, "/24")}"]
    }



    user_account {
      keys     = [trimspace(tls_private_key.homelab_key.public_key_openssh)]
      username = "almalinux"
    }
  }

  cpu {
    type  = "host"
    cores = 2
  }
  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = local.datastore_id
    file_id      = proxmox_virtual_environment_download_file.latest_almalinux_9-4_qcow2.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 10
  }

  efi_disk {
    datastore_id = local.datastore_id
    file_format  = "raw"
    type         = "4m"
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }
}

# key generation
resource "tls_private_key" "homelab_key" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "homelab_key" {
  content  = tls_private_key.homelab_key.private_key_openssh
  filename = "${path.module}/homelab_key"
}
