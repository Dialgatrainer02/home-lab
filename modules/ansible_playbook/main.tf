resource "random_id" "rng_id" {
  byte_length = 4
}
resource "local_file" "inventory" {
  filename = "${path.module}/.inventory-${random_id.rng_id.id}.json"
  content  = jsonencode(var.inventory)
}

resource "terraform_data" "trigger_playbook" {
  triggers_replace = local_file.inventory.id
  provisioner "local-exec" {
    command = "ansible-playbook ${var.playbook_path} -i ${local_file.inventory.filename} ${var.extra_vars != null ? "-e" : ""} \" ${var.extra_vars != null ? jsonencode(var.extra_vars) : ""} \" "
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = var.ansible_settings.host_key_checking
      ANSIBLE_PRIVATE_KEY_FILE  = var.ansible_settings.private_key_file
      ANSIBLE_REMOTE_USER       = var.ansible_settings.ssh_user
      ANSIBLE_SSH_PIPELINING    = true
      ANSIBLE_STDOUT_CALLBACK   = var.ansible_settings.ansible_callback
    }
  }

}