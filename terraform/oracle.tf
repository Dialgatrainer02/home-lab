# make vcn
# make subnet
# make security rules
# make compute instance
# get attached vnic id
# get public ip from vnic





resource "oci_core_virtual_network" "wireguard_vcn" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "instanceVCN"
  dns_label      = "instancevcn"
  is_ipv6enabled = true
}

resource "oci_core_dhcp_options" "wireguard_dhcp_options" {
  #Required
  compartment_id = var.compartment_ocid
  options {
    type               = "DomainNameServer"
    server_type        = "CustomDnsServer"
    custom_dns_servers = ["1.1.1.1"]
  }
  display_name = "Wireguard DHCP Options"
  vcn_id       = oci_core_virtual_network.wireguard_vcn.id
}

resource "oci_core_subnet" "wireguard_subnet" {
  cidr_block        = "10.1.20.0/24"
  display_name      = "instanceSubnet"
  dns_label         = "instancesubnet"
  security_list_ids = [oci_core_security_list.wireguard_security_list.id]
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.wireguard_vcn.id
  route_table_id    = oci_core_route_table.wireguard_route_table.id
  dhcp_options_id   = oci_core_dhcp_options.wireguard_dhcp_options.id
  ipv6cidr_block    = "${substr(oci_core_virtual_network.wireguard_vcn.ipv6cidr_blocks[0], 0, length(oci_core_virtual_network.wireguard_vcn.ipv6cidr_blocks[0]) - 2)}${64}"
}

resource "oci_core_internet_gateway" "wireguard_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "testIG"
  vcn_id         = oci_core_virtual_network.wireguard_vcn.id
}

resource "oci_core_route_table" "wireguard_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.wireguard_vcn.id
  display_name   = "testRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.wireguard_internet_gateway.id
  }
}

resource "oci_core_security_list" "wireguard_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.wireguard_vcn.id
  display_name   = "WireguardSecurityList"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
  egress_security_rules {
    protocol    = "all"
    destination = "::/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "::/0"

    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    protocol = "17"
    source   = "0.0.0.0/0"

    udp_options {
      max = "53"
      min = "53"
    }
  }
  ingress_security_rules {
    protocol = "17"
    source   = "::/0"

    udp_options {
      max = "53"
      min = "53"
    }
  }
}


resource "oci_core_instance" "wireguard_instance" {
  for_each            = var.oracle
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = each.key
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.wireguard_subnet.id
    display_name     = "primaryvnic"
    assign_public_ip = true
    hostname_label   = each.key
    assign_ipv6ip    = true
  }

  source_details {
    source_type = "image"
    source_id   = lookup(data.oci_core_images.images.images[0], "id")
  }

  metadata = {
    ssh_authorized_keys = trimspace(tls_private_key.homelab_key.public_key_openssh)
  }
}
resource "terraform_data" "provision" {
  for_each = var.oracle
  input    = data.oci_core_instance.wireguard_instance[each.key].public_ip
  connection {
    type        = "ssh"
    host        = data.oci_core_instance.wireguard_instance[each.key].public_ip
    user        = "opc"
    private_key = tls_private_key.homelab_key.private_key_openssh
  }
  provisioner "remote-exec" {
    inline = [ # add swap as 1 g memory nd 1 g swap isnt enough for dnf to work
      "sudo swapoff -a",
      "sudo dd if=/dev/zero of=/.swapfile bs=512M count=8", #512M * 8 = 4GB
      "sudo mkswap /.swapfile",
      "sudo swapon /.swapfile"
    ]
  }

}

