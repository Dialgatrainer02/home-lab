variable "containers" {
  type = map(object({ id = number, ansible_groups = list(string), ansible_varibles = optional(any) }))

  default = {
    dns1 = {
      id             = 1
      ansible_groups = ["dns"]
    }
    dns2 = {
      id             = 2
      ansible_groups = ["dns"]
    }
    prometheus = {
      id             = 3
      ansible_groups = ["logging"]
    }
    loki = {
      id             = 4
      ansible_groups = ["logging"]
    }
    grafana = {
      id             = 5
      ansible_groups = ["logging"]
    }
  }
}



variable "vms" {
  type = map(object({ id = number, ansible_groups = list(string), ansible_varibles = optional(map(string)) }))

  default = {
    docker = {
      id             = 6
      ansible_groups = ["wireguard", "arrstack", "minecraft"]
      ansible_varibles = {
        wireguard_remote_directory     = "/opt/arrstack/config/wireguard"
        wireguard_service_enabled      = "no"
        wireguard_service_state        = "stopped"
        wireguard_interface            = "wg0"
        wireguard_port                 = "51820"
        wireguard_addresses            = "10.50.0.2/24" # should be yaml list
        wireguard_endpoint             = "hn-1-prx.duckdns.org"
        wireguard_allowed_ips          = "10.50.0.2/32"
        wireguard_persistent_keepalive = "30"
      }
    }
  }
}

variable "oracle" {
  type = map(object({ id = number, ansible_groups = list(string), ansible_varibles = optional(map(any)) }))
  default = {
    wireguard-oci = {
      id             = 7
      ansible_groups = ["wireguard"]
      ansible_varibles = {
        wireguard_interface         = "wg0"
        wireguard_interface_restart = true
        wireguard_port              = "51820"
        wireguard_addresses         = "10.50.0.1/24" # should be yaml list
        wireguard_endpoint          = "oc-1-vps.duckdns.org"
        wireguard_allowed_ips       = "0.0.0.0/0. ::/0"
        wireguard_postup            = "nft add table ip wireguard; nft add chain ip wireguard wireguard_chain {type nat hook postrouting priority srcnat\\; policy accept\\;}; nft add rule ip wireguard wireguard_chain counter packets 0 bytes 0 masquerade; nft add table ip6 wireguard; nft add chain ip6 wireguard wireguard_chain {type nat hook postrouting priority srcnat\\; policy accept\\;}; nft add rule ip6 wireguard wireguard_chain counter packets 0 bytes 0 masquerade" # should be yaml list
        wireguard_postdown          = "nft delete table ip wireguard; nft delete table ip6 wireguard"                                                                                                                                                                                                                                                                                                                                                                                     # should be yaml list
      }
    }
  }
}
