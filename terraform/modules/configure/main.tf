resource "local_file" "extra_vars" {
  filename = "${path.module}/extra_vars.yml"
  content  = "--- \n${yamlencode(var.extra_vars)}" # alittle hacky but ultimatly fine
}



resource "local_file" "inventory" {
  filename = "${path.root}/../ansible/inventory.yml"
  content  = yamlencode(var.inventory)
  provisioner "local-exec" {
    command     = "ansible-playbook ${var.playbook} -i ${local_file.inventory.filename} -e \"@${local_file.extra_vars.filename}\" "
    working_dir = path.root
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = var.host_key_checking
      ANSIBLE_PRIVATE_KEY_FILE  = var.private_key_file
      ANSIBLE_REMOTE_USER       = var.ssh_user
    }
    quiet = var.quiet
  }
}


