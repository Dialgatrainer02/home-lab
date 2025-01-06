terraform {
  required_version = "1.8.8"
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.5.2"
    }
    random = {
      source = "hashicorp/random"
      version = "3.6.3"
    }
  }
}