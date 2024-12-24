resource "oci_core_virtual_network" "oci_vcn" {
  cidr_block     = var.vcn_ip_range
  compartment_id = var.compartment_ocid
  display_name   = var.vcn_label
  dns_label      = var.vcn_dns_label
  is_ipv6enabled = var.ipv6_enabled
}

resource "oci_core_dhcp_options" "oci_dhcp_options" {
  compartment_id = var.compartment_ocid
  options {
    type               = "DomainNameServer"
    server_type        = "CustomDnsServer"
    custom_dns_servers = var.dhcp_dns
  }
  display_name = var.dhcp_label
  vcn_id       = oci_core_virtual_network.oci_vcn.id
}

resource "oci_core_subnet" "oci_subnet" {
  cidr_block        = var.subnet_ip_range
  display_name      = var.subnet_label
  dns_label         = var.subnet_dns_label
  security_list_ids = [oci_core_security_list.oci_security_list.id]
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.oci_vcn.id
  route_table_id    = oci_core_route_table.oci_route_table.id
  dhcp_options_id   = oci_core_dhcp_options.oci_dhcp_options.id
  ipv6cidr_block    = var.ipv6_enabled ? "${substr(oci_core_virtual_network.oci_vcn.ipv6cidr_blocks[0], 0, length(oci_core_virtual_network.oci_vcn.ipv6cidr_blocks[0]) - 2)}${64}" : null
}

resource "oci_core_internet_gateway" "oci_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = var.gw_label
  vcn_id         = oci_core_virtual_network.oci_vcn.id
}

resource "oci_core_route_table" "oci_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oci_vcn.id
  display_name   = var.route_label

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oci_internet_gateway.id
  }
}

resource "oci_core_security_list" "oci_security_list" { ## null values making headaches
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oci_vcn.id
  display_name   = var.security_label

  dynamic "egress_security_rules" {
    for_each = var.egress_rules
    content {
      protocol    = egress_security_rules.value.protocol
      destination = egress_security_rules.value.destination

      udp_options {
        max = egress_security_rules.value.udp_options.max
        min = egress_security_rules.value.udp_options.min
      }
      tcp_options {
        max = egress_security_rules.value.tcp_options.max
        min = egress_security_rules.value.tcp_options.min
      }

    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.ingress_rules
    content {
      protocol = ingress_security_rules.value.protocol
      source   = ingress_security_rules.value.source

      udp_options {
        max = ingress_security_rules.value.udp_options.max
        min = ingress_security_rules.value.udp_options.min
      }
      tcp_options {
        max = ingress_security_rules.value.tcp_options.max
        min = ingress_security_rules.value.tcp_options.min
      }

    }
  }
}



resource "oci_core_instance" "oci_instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_label
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.oci_subnet.id
    display_name     = var.nic_label
    assign_public_ip = true
    hostname_label   = var.hostname
    assign_ipv6ip    = var.ipv6_enabled
  }

  source_details {
    source_type = "image"
    source_id   = lookup(data.oci_core_images.images.images[0], "id") ### again unsure how to make a varible
  }

  metadata = {
    ssh_authorized_keys = var.public_key
  }
}
resource "terraform_data" "provision" {
  input = oci_core_instance.oci_instance.public_ip
  connection {
    type        = "ssh"
    host        = oci_core_instance.oci_instance.public_ip
    user        = "opc"
    private_key = var.private_key ## dont like this
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
