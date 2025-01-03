module "alloy_config" {
  source = "../../ansible_playbook"

  playbook_path = ".playbooks/helpers/alloy-playbook.yml"
  inventory = {
    alloy = {
      hosts = var.host
    }
  }
  ansible_settings = {
    private_key_file = var.helper.private_key_file
    ssh_user         = var.helper.user
    ansible_callback = var.helper.callback
  }
  extra_vars = var.alloy_vars

}