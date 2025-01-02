resource "local_file" "inventory" {
  
}

resource "terraform_data" "trigger_playbook" {
    triggers_replace = local_file.inventory.id
    provisioner "local-exec" {
        command = "ansible-playbook ${var.playbook_path} -i ${local_file.inventory.filename} ${var.extra_vars != null? "-e": "" } ${var.extra_vars != null?  \' jsonencode(var.extra_vars) \'  : "" }"
        environment = {
        ANSIBLE_HOST_KEY_CHECKING = var.host_key_checking # make these into ansible_setting object
        ANSIBLE_PRIVATE_KEY_FILE  = var.private_key_file
        ANSIBLE_REMOTE_USER       = var.ssh_user
        ANSIBLE_SSH_PIPELINING    = true
        ANSIBLE_STDOUT_CALLBACK   = var.ansible_callback
        }
    }
  
}