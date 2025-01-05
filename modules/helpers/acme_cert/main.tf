module "dns_update" {
  source = "../../ansible_playbook"

  playbook_path = ".playbooks/helpers/cert-playbook.yml"
  inventory = {

    hosts = var.host
  }
  ansible_settings = {
    private_key_file = var.helper.private_key_file
    ssh_user         = var.helper.user
    ansible_callback = var.helper.callback
  }
  extra_vars = var.cert_vars

}