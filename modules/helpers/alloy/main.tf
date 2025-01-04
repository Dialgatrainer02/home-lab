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
  extra_vars = merge(var.alloy_vars, local.config)

}

locals {
  config = { alloy_config = <<EOF
  prometheus.exporter.unix "host" { }

prometheus.exporter.self "alloy" { }

prometheus.scrape "host" {
targets    = prometheus.exporter.unix.host.targets
forward_to = [prometheus.remote_write.staging.receiver]
}
prometheus.scrape "alloy" {
targets    = prometheus.exporter.self.alloy.targets
forward_to = [prometheus.remote_write.staging.receiver]
}

{% if service_type == "dns" %}
prometheus.exporter.dnsmasq "dns" {
  address = "localhost:53"
}

prometheus.scrape "dnsmasq"{
  targets  = prometheus.exporter.dnsmasq.dns.targets
  forward_to = [prometheus.remote_write.staging.receiver]
}

{% endif %}

prometheus.remote_write "staging" {
  endpoint {
    url = "{{ prometheus_endpoint }}"
  }
}

local.file_match "tmplogs" {
  path_targets = [
    {__path__ = "/tmp/*.log"},
  ]
  sync_period = "5s"
}

loki.relabel "journal" {
  forward_to = []

  rule {
    source_labels = ["__journal__systemd_unit"]
    target_label  = "unit"
  }

  rule {
    source_labels = ["__journal__hostname"]
    target_label  = "hostname"
  }
  rule {
    source_labels = ["__journal__boot_id"]
    target_label  = "boot_id"
  }
}


loki.source.file "tmpfiles" {
  targets    = local.file_match.tmplogs.targets
  forward_to = [loki.write.local.receiver]
}
loki.source.journal "read"  {
  relabel_rules = loki.relabel.journal.rules
  forward_to    = [loki.write.local.receiver]
}
loki.write "local" {
  endpoint {
    url = "{{ loki_endpoint }}"
  }
}
  EOF
  }
}