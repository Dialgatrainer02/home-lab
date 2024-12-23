# module "oci_vps" {
#   source = "./modules/oci_vm"

#   tenancy_ocid     = var.tenancy_ocid
#   compartment_ocid = var.compartment_ocid
#   region           = var.region
#   user_ocid        = var.user_ocid
#   fingerprint      = var.fingerprint
#   oci_private_key  = var.oci_private_key
#   public_key       = tls_private_key.staging_key.public_key_openssh
#   private_key      = tls_private_key.staging_key.private_key_openssh

#   vcn_ip_range    = "10.0.0.0/16"
#   vcn_label       = "wg_vcn"
#   dhcp_dns        = ["1.1.1.1", "1.0.0.1"]
#   subnet_ip_range = "10.99.0.1/24"
#   subnet_label    = "wg_subnet"
#   gw_label        = "wg_gw"
#   security_label  = "wg_security"
#   ingress_rules = [{ # wireguard and ssh
#     protocol    = "17"
#     source      = "0.0.0.0/0"
#     # tcp_options = null
#     udp_options = { min = 51820, max = 51820 }
#     },
#     {
#       protocol    = "6"
#       source      = "0.0.0.0/0"
#       tcp_options = { min = 22, max = 22 }
#       # udp_options = null
#   }]
#   instance_label = "wireguard_instance"
#   hostname       = "wireguard_oci"

# }