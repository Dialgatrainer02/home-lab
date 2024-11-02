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
}

resource "oci_core_subnet" "wireguard_subnet" {
  cidr_block        = "10.1.20.0/24"
  display_name      = "instanceSubnet"
  dns_label         = "instancesubnet"
  security_list_ids = [oci_core_security_list.wireguard_security_list.id]
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.wireguard_vcn.id
  route_table_id    = oci_core_route_table.wireguard_route_table.id
  dhcp_options_id   = oci_core_virtual_network.wireguard_vcn.default_dhcp_options_id
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
    protocol    = "6"
    destination = "0.0.0.0/0"
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
    source   = "0.0.0.0/0"

    tcp_options {
      max = "3000"
      min = "3000"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "3005"
      min = "3005"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "80"
      min = "80"
    }
  }
  ingress_security_rules {
    protocol = "17"
    source   = "0.0.0.0/0"

    udp_options {
      max = "51820"
      min = "51820"
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
  }

  source_details {
    source_type = "image"
    source_id   = lookup(data.oci_core_images.images.images[0], "id")
  }

  metadata = {
    ssh_authorized_keys = trimspace(tls_private_key.homelab_key.public_key_openssh)
  }
}


