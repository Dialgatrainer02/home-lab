variable "compute" {
  type = object({
    ad            = optional(number, 3)
    vcn_label     = optional(string, "oci_vcn")
    vcn_dns_label = optional(string, "OCIVCN")
    vcn_ip_range  = optional(string, "10.0.0.0/16")
    ipv6_enabled  = optional(bool, true)

    dhcp_dns   = optional(list(string), ["1.1.1.1", "1.0.0.1"])
    dhcp_label = optional(string, "oci_dhcp")

    subnet_label     = optional(string, "oci_subnet")
    subnet_dns_label = optional(string, "OCISubnet")
    subnet_ip_range  = optional(string, "10.10.10.0/24")

    gw_label       = optional(string, "oci_gateway")
    route_label    = optional(string, "oci_route_tabel")
    security_label = optional(string, "oci_security")

    egress_rules = list(object({
      protocol    = optional(string, "all")
      destination = optional(string, "0.0.0.0/0")
      udp_options = optional(object({
        min = optional(number)
        max = optional(number)
      }))
      tcp_options = object({
        min = optional(number)
        max = optional(number)
      })
    }))
    ingress_rules = list(object({
      protocol = optional(string, "6")
      source   = optional(string, "0.0.0.0")
      tcp_options = optional(object({
        min = optional(number, 22)
        max = optional(number, 22)
      }))
      udp_options = optional(object({
        min = optional(number)
        max = optional(number)
      }))
    }))
    instance_label                      = optional(string, "oci_instance")
    instance_shape                      = optional(string, "VM.Standard.E2.1.Micro")
    instance_ocpus                      = optional(number, 1)
    instance_shape_config_memory_in_gbs = optional(number, 1)
    nic_label                           = optional(string, "oci_instance_nic")
    hostname                            = optional(string, "oci_hostname")
    gen_keypair                         = optional(bool, true)
    public_key                          = optional(string)
    private_key                         = optional(string)
    host_vars                           = optional(any)
  })
}

locals {
  public_key  = var.compute.gen_keypair ? tls_private_key.staging_key[0].public_key_openssh : var.compute.public_key
  private_key = var.compute.gen_keypair ? tls_private_key.staging_key[0].private_key_openssh : var.compute.private_key
}

locals {
  ipv4_address = oci_core_instance.oci_instance.public_ip
  host_vars    = merge(var.compute.host_vars, { ansible_host = local.ipv4_address })
  host = {
    "${var.compute.hostname}" = local.host_vars
  }
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.oci_settings.compartment_ocid
  ad_number      = var.compute.ad
}

data "oci_core_images" "images" {
  compartment_id           = var.oci_settings.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = 9
  shape                    = var.compute.instance_shape
}

variable "oci_settings" {
  type = object({
    region           = string
    tenancy_ocid     = string
    user_ocid        = string
    fingerprint      = string
    oci_private_key  = string
    compartment_ocid = string
  })
}