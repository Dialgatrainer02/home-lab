packer {
  required_plugins {
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
    lxc = {
      source = "github.com/hashicorp/lxc"
      version = "~> 1"
    }
  }
}


source "lxc" "base" {
  config_file         = "~/.config/lxc/default.conf"
  template_name       = "download"
  template_parameters = ["-d", "almalinux", "-a", "amd64", "-r", 9 ]

}

build {
    name = "base"
    sources = ["lxc.base"]


    provisioner "shell" {
        script = "./scripts/ssh.sh"
    }

    provisioner "breakpoint" {}

    provisioner "ansible" {
    ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
    user = build.User
    playbook_file    = "ansible/base-playbook.yml"
    galaxy_file = "ansible/requirements.yml"
    use_proxy       = false
    extra_arguments = [ "-vvvv", ]
  }
}

variables {
  dns = {
    dns_0 = {

    } 
    dns_1 = {

    }
  }

}
build {
  name = "specalise"
  // dynamic "source" {
  //   for_each = var.dns #dont need to do this as all the configs are the same so should just be abl x3 and work.
  //   labels = ["lxc.base"]
  //   content {
  //     name = source.key
  //     output_directory = "build/${source.key}"
  //   }
  // }
  source "lxc.base" {
    name = "dns"
  }

  // provisioner "shell" {
    // inline = ["cat /etc/machine-id"]
  // }

  provisioner "ansible" {
    ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
    user = "root"
    playbook_file    = "ansible/dns-playbook.yml"
    galaxy_file = "ansible/requirements.yml"
    use_proxy       = false
    extra_arguments = [ "-vvvv", ]
  }
}