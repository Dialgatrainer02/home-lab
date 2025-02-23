
source "proxmox-iso" "alma-k8" {
  boot_command    = ["<up><tab>e<wait><down><down><end>  ip=dhcp inst.cmdline inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks-k8.cfg<f10>"]
  boot_wait       = "7s"
  bios            = "ovmf"
  machine         = "q35"
  qemu_agent      = true
  cpu_type        = "host"
  cores           = 2
  memory          = 2048
  os = "l26"
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "10G"
    storage_pool = "local-zfs"
    type         = "scsi"
    format       = "raw"
  }
  efi_config {
    efi_storage_pool  = "local-zfs"
    efi_type          = "4m"
    pre_enrolled_keys = false
    efi_format        = "raw"
  }
  http_directory           = "${path.root}/.kickstart"
  insecure_skip_tls_verify = true
  boot_iso {
    iso_checksum = "none"
    iso_urls = ["./downloaded_iso_path/977ffa5c530f281d5418b688b30333cdc55877b9.iso",
    "https://repo.almalinux.org/almalinux/9.5/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso"]
    // iso_download_pve = true
    iso_storage_pool = "local"
    unmount          = true
  }
  cloud_init              = true
  cloud_init_storage_pool = "local-zfs"
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  node                 = "${var.pve_node}"
  password             = "${var.pve_password}"
  username             = "${var.pve_username}"
  proxmox_url          = "${var.pve_endpoint}"
  ssh_password         = "${var.provision_passwd}"
  ssh_timeout          = "15m"
  ssh_username         = "${var.provision_user}"
  template_description = "Almalinux, generated on ${timestamp()}. Made by Packer"
  
}

source "proxmox-iso" "alma-nfs" { # lxc and packer dont mix very well so using full vm instead
  boot_command    = ["<up><tab>e<wait><down><down><end>  ip=dhcp inst.cmdline inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks-nfs.cfg<f10>"]
  boot_wait       = "7s"
  bios            = "ovmf"
  machine         = "q35"
  qemu_agent      = true
  cpu_type        = "host"
  cores           = 2
  memory          = 2048
  os = "l26"
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "10G"
    storage_pool = "local-zfs"
    type         = "scsi"
    format       = "raw"
  }
  efi_config {
    efi_storage_pool  = "local-zfs"
    efi_type          = "4m"
    pre_enrolled_keys = false
    efi_format        = "raw"
  }
  http_directory           = "${path.root}/.kickstart"
  insecure_skip_tls_verify = true
  boot_iso {
    iso_checksum = "none"
    iso_urls = ["./downloaded_iso_path/977ffa5c530f281d5418b688b30333cdc55877b9.iso",
    "https://repo.almalinux.org/almalinux/9.5/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso"]
    // iso_download_pve = true
    iso_storage_pool = "local"
    unmount          = true
  }
  cloud_init              = true
  cloud_init_storage_pool = "local-zfs"
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  node                 = "${var.pve_node}"
  password             = "${var.pve_password}"
  username             = "${var.pve_username}"
  proxmox_url          = "${var.pve_endpoint}"
  ssh_password         = "${var.provision_passwd}" #@TERRAFORM lock delete or disable password auth as i dont like this
  ssh_timeout          = "10m"
  ssh_username         = "${var.provision_user}"
  template_description = "Almalinux, generated on ${timestamp()}. Made by Packer"
  template_name        = "almalinux-nfs"
  vm_name              = "alamlinux-nfs"
  vm_id                = 902
  tags                 = "almalinux;packer;nfs"
}

source "proxmox-iso" "alpine-lb" {
  boot_command    = [
    "root<enter><enter><wait>",
    "ip link set eth0 up && udhcpc -i eth0<enter><wait5>",
    "wget -O /etc/local.d/setup.start http://{{ .HTTPIP }}:{{ .HTTPPort }}/setup.sh<enter><wait1>",
    "chmod +x /etc/local.d/setup.start<enter>",
    "service local start<enter>"
  ]
  boot_wait       = "15s"
  bios            = "ovmf"
  machine         = "q35"
  qemu_agent      = true
  cpu_type        = "host"
  cores           = 2
  memory          = 2048
  os = "l26"
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "10G"
    storage_pool = "local-zfs"
    type         = "scsi"
    format       = "raw"
  }
  efi_config {
    efi_storage_pool  = "local-zfs"
    efi_type          = "4m"
    pre_enrolled_keys = false
    efi_format        = "raw"
  }
  http_directory           = "${path.root}/.answers"
  insecure_skip_tls_verify = true
  boot_iso {
    iso_checksum = "none"
    iso_urls = [
      "./downloaded_iso_path/f8616b98ce61f0fd48072be38602c01be6df7554.iso",
    "https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-standard-3.21.3-x86_64.iso"]
    // iso_download_pve = true
    iso_storage_pool = "local"
    unmount          = true
  }
  cloud_init              = true
  cloud_init_storage_pool = "local-zfs"
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  node                 = "${var.pve_node}"
  password             = "${var.pve_password}"
  username             = "${var.pve_username}"
  proxmox_url          = "${var.pve_endpoint}"
  ssh_password         = "${var.provision_passwd}"
  ssh_timeout          = "10m"
  ssh_username         = "${var.provision_user}"
  template_description = "Alpine, generated on ${timestamp()}. Made by Packer"
  template_name        = "alpine-lb"
  vm_name              = "alpine-lb"
  vm_id                = 903
  tags                 = "alpine;packer;lb"
}

// build {
  // sources = ["source.proxmox-iso.alma-k8"]
  // provisioner "shell" {
  // inline = [
    // "setup-cloud-init",
    // "echo 'datasource_list: [ NoCloud, ConfigDrive ]' > /etc/cloud/cloud.cfg.d/99_pve.cfg"
  // ]
  // }
// }

build {
  source "source.proxmox-iso.alma-k8" {
    name = "master"
    tags = "almalinux;packer;k8;master"
    template_name        = "almalinux-master"
    vm_name              = "alamlinux-master"
    vm_id = 900
  }
  // provisioner "breakpoint" {}

  provisioner "shell" {
    inline = [
      "sudo kubeadm config images pull"
    ]
  }


  provisioner "shell" {
    inline = [
      "sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
    ]
  }
}

build {
  source "source.proxmox-iso.alma-k8" {
    name = "worker"
    tags = "almalinux;packer;k8;worker"
    template_name        = "almalinux-worker"
    vm_name              = "alamlinux-worker"
    vm_id = 901
  }

  provisioner "shell" {
    inline = [
      "sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
    ]
  }
}

build {
  sources = ["source.proxmox-iso.alma-nfs",]

  provisioner "shell" {
    inline = [
      "sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
    ]
  }
}


// build {
  // sources = ["source.proxmox-iso.alpine-lb"]
// 
  // provisioner "shell" {
    // inline = [
      // "apk add haproxy-openrc keepalived",
      // "rc-update add haproxy boot",
      // "rc-update add keepalived boot" 
    // ]
  // }
// 
// }