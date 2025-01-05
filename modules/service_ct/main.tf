
module "service_ct" {
  source = "../prmoxmox/container"

  container = merge({
    hostname    = var.service.service_name
    description = var.service.service_description
    os_image    = var.service.service_os_image
    os_type     = var.service.service_os_type
    host_vars   = var.service.host_vars
  }, var.service.service_ipv4, var.service.custom_ct)
  pve_settings = var.pve_settings
}

resource "local_sensitive_file" "service_private_key" {
  filename = ".keys/${var.service.service_name}_private_key"
  content  = local.private_key
}

module "alloy" {
  count = var.alloy.install ? 1 : 0

  depends_on = [module.service_ct]
  source     = "../helpers/alloy"

  host = module.service_ct.ansible_inventory
  alloy_vars = merge({
    service_type        = var.service.service_type
    loki_endpoint       = var.alloy.endpoints.loki
    prometheus_endpoint = var.alloy.endpoints.prom

  }, {})
  helper = {
    private_key_file = local_sensitive_file.service_private_key.filename

  }
}

module "dns_entry" {
  count = var.dns.entry ? 1 : 0

  depends_on = [module.service_ct]
  source     = "../helpers/update_dns"

  host = var.dns.host
  dns_vars = {
    dns_entry_name = var.service.service_name
    dns_entry_addr = module.service_ct.ipv4_address
  }
  helper = {
    private_key_file = var.dns.private_key_path
    callback         = "default"
  }
}

module "service_config" {
  source     = "../ansible_playbook"
  depends_on = [module.service_ct]

  playbook_path = ".playbooks/${var.service.service_type}-playbook.yml"
  inventory = {
    "${var.service.service_type}" = {
      hosts = module.service_ct.ansible_inventory
    }
  }
  ansible_settings = {
    private_key_file = local_sensitive_file.service_private_key.filename # also recommend placing in hostvars for when more complex roles come in
    ssh_user         = "root"
    ansible_callback = "default"
  }
  extra_vars = var.service_vars

}