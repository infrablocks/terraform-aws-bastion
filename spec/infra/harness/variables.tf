variable "region" {}

variable "component" {}
variable "deployment_identifier" {}

variable "ami" {}
variable "instance_type" {}

variable "ssh_public_key_path" {}

variable "allowed_cidrs" {
  type = list(string)
}
variable "egress_cidrs" {
  type = list(string)
}

variable "minimum_instances" {}
variable "maximum_instances" {}
variable "desired_instances" {}
