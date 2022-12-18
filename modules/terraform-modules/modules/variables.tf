variable "environment" {
    default = "dev"
}

variable "address_space" {
  default = "10.0.0.0/16"
}

variable "public_address_prefixes" {
  default = "10.0.1.0/24"
}

variable "private_address_prefixes" {
  default = "10.0.2.0/24"
}
