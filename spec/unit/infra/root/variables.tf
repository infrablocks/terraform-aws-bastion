variable "region" {}

variable "component" {}
variable "deployment_identifier" {}

variable "subnet_ids" {
  type = list(string)
  default = null
}

variable "ami" {
  default = null
}
variable "instance_type" {
  default = null
}

variable "ssh_public_key_path" {}

variable "allowed_cidrs" {
  type = list(string)
}
variable "egress_cidrs" {
  type = list(string)
}

variable "minimum_instances" {
  default = null
}
variable "maximum_instances" {
  default = null
}
variable "desired_instances" {
  default = null
}

variable "associate_public_ip_address" {
  default = null
}
