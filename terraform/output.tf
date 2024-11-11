output "wireguard_ip" {
  value = oci_core_instance.wireguard_instance["wireguard-oci"].public_ip

}