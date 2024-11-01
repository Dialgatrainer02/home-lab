variable "containers" {
    type = map(any)

    default = {
        adguard1 = {
            ansible_groups = ["adguards"]
            ansible_varibles = {""}
        }
        adguard2 = {
            ansible_groups = ["adguards"]
            ansible_varibles = {""}
        }
        prometheus = {
            ansible_groups = ["logging"]
        }
        loki = {
            ansible_groups = ["logging"]
        }
        grafana = {
            ansible_groups = ["logging"]
        }
    }
}

variable "vms" {
    type = map(any)

    default = {
        docker = {
            ansible_groups = ["wireguard","arrstack","minecraft"]
            ansible_varibles = {
                wireguard_remote_directory = "/opt/arrstack/config/wireguard"
                wireguard_service_enabled = "no"
                wireguard_service_state = "stopped"
                wireguard_interface = "wg0"
                wireguard_port = "51820"
                wireguard_addresses = yamlencode(["10.50.0.2/24"])
                wireguard_endpoint = "hn-1-prx.duckdns.org"
                wireguard_allowed_ips = "10.50.0.2/32"
                wireguard_persistent_keepalive = "30"
            }
        }
    }
}

variable "oracle" {
    type = map(any)
    default = {
      wireguard-oci = {
            ansible_groups = ["wireguard"]
            ansible_varibles = {
                wireguard_interface = "wg0"
                wireguard_interface_restart = true
                wireguard_port = "51820"
                wireguard_addresses = yamlencode(["10.50.0.1/24"])
                wireguard_endpoint = "oc-1-vps.duckdns.org"
                wireguard_allowed_ips = "0.0.0.0/0. ::/0"
                wireguard_postup = yamlencode([])
                wireguard_postdown =  yamlencode([])
            }
        }
    }  
}