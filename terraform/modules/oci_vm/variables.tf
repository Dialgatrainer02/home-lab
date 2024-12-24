data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = var.ad
}

data "oci_core_images" "images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = 9
  shape                    = var.instance_shape
}

locals {
  host_vars = merge(var.host_vars, { ansible_host = oci_core_instance.oci_instance.public_ip })
  host = {
    "${var.hostname}" = local.host_vars
  }
}
variable "vcn_ip_range" {
  description = "The CIDR block for the VCN."
  type        = string
  default     = "10.0.0.0/16"
}

variable "region" {
  description = "The OCI region where resources will be created."
  type        = string
}

variable "tenancy_ocid" {
  description = "The OCID of the tenancy in OCI."
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user in OCI."
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the API key for the user."
  type        = string
}

variable "oci_private_key" {
  description = "the private key for OCI API access."
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment where resources will be created."
  type        = string
}

variable "vcn_label" {
  description = "Display name for the Virtual Cloud Network (VCN)."
  type        = string
  default     = "oci_vcn"
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN."
  type        = string
  default     = "ociVCN"
}

variable "ipv6_enabled" {
  description = "Enable IPv6 for the VCN and related resources."
  type        = bool
  default     = true
}

variable "dhcp_dns" {
  description = "Custom DNS servers for the DHCP options."
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "dhcp_label" {
  description = "Display name for the DHCP options."
  type        = string
  default     = "oci_dhcp_options"
}

variable "subnet_ip_range" {
  description = "The CIDR block for the subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_label" {
  description = "Display name for the subnet."
  type        = string
  default     = "oci_subnet"
}

variable "subnet_dns_label" {
  description = "DNS label for the subnet."
  type        = string
  default     = "oci-subnet-dns"
}

variable "gw_label" {
  description = "Display name for the Internet Gateway."
  type        = string
  default     = "oci_internet_gateway"
}

variable "route_label" {
  description = "Display name for the Route Table."
  type        = string
  default     = "oci_route_table"
}

variable "security_label" {
  description = "Display name for the Security List."
  type        = string
  default     = "oci_security_list"
}

variable "ingress_rules" {
  description = "List of ingress security rules."
  type = list(object({
    protocol    = string
    source      = string
    tcp_options = optional(object({ min = optional(number), max = optional(number) }), {})
    udp_options = optional(object({ min = optional(number), max = optional(number) }), {})
  }))
  default = [
    {
      protocol = "6"
      source   = "0.0.0.0/0"
      tcp_options = {
        max = 22
        min = 22
      }
    }
  ]
}

variable "egress_rules" {
  description = "List of egress security rules."
  type = list(object({
    protocol    = string
    destination = string
    tcp_options = optional(object({ min = optional(number), max = optional(number) }), {})
    udp_options = optional(object({ min = optional(number), max = optional(number) }), {})
  }))
  default = [
    {
      protocol    = "all"
      destination = "0.0.0.0/0"
    },
    {
      protocol    = "all"
      destination = "::/0"
    }
  ]
}

variable "ad" {
  description = "avalbility domain"
  type        = number
  default     = 3

}

variable "instance_label" {
  description = "Display name for the compute instance."
  type        = string
  default     = "oci_instance"
}

variable "instance_shape" {
  description = "Shape of the compute instance."
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "instance_ocpus" {
  description = "Number of OCPUs for the instance."
  type        = number
  default     = 1
}

variable "instance_shape_config_memory_in_gbs" {
  description = "Memory in GB for the instance shape configuration."
  type        = number
  default     = 1
}

variable "nic_label" {
  description = "Display name for the VNIC."
  type        = string
  default     = "oci_vnic"
}

variable "hostname" {
  description = "Hostname label for the instance."
  type        = string
  default     = "oci-1"
}

variable "public_key" {
  description = "SSH public key for instance access."
  type        = string
}

variable "private_key" {
  description = "SSH private key for provisioning. This should be kept secure."
  type        = string
}

variable "host_vars" {
  description = "extra host vars you want to use in ansible"
  type        = any
  default     = {}
}

output "oci_public_ip" {
  value = oci_core_instance.oci_instance.public_ip

}

output "host" {
  value = local.host
}