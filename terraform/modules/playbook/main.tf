resource "random_id" "suffix" {
  byte_length = 1

}

resource "local_sensitive_file" "extra_vars" {
  filename = "${path.module}/extra_vars-${random_id.suffix.id}.yml"
  content  = "--- \n${yamlencode(var.extra_vars)}" # alittle hacky but ultimatly fine
}


resource "local_file" "inventory" {
  filename = "${path.module}/inventory-${random_id.suffix.id}.yml"
  content  = yamlencode(var.inventory)
}


resource "terraform_data" "playbook" {
  triggers_replace = [
    local_sensitive_file.extra_vars.id,
    local_file.inventory.id
  ]
  provisioner "local-exec" {
    command     = "ansible-playbook ${var.playbook} -i ${local_file.inventory.filename} -e \"@${local_sensitive_file.extra_vars.filename}\"  "
    working_dir = path.root
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = var.host_key_checking
      ANSIBLE_PRIVATE_KEY_FILE  = var.private_key_file
      ANSIBLE_REMOTE_USER       = var.ssh_user
      ANSIBLE_SSH_PIPELINING    = true
    }
    quiet = var.quiet
  }
}