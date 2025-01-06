terraform {
  required_version = "1.8.8"
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "6.21.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }
}

provider "oci" {
  region       = var.oci_settings.region
  tenancy_ocid = var.oci_settings.tenancy_ocid
  user_ocid    = var.oci_settings.user_ocid
  fingerprint  = var.oci_settings.fingerprint
  private_key  = var.oci_settings.oci_private_key
}