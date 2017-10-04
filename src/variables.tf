variable "region" {}
variable "vpc_id" {}
variable "subnet_ids" {
  type = "list"
}

variable "component" {}
variable "deployment_identifier" {}

variable "ami" {}
variable "instance_type" {
  default = "t2.nano"
}
variable "ssh_public_key_path" {}

variable "allowed_cidrs" {
  type = "list"
}
variable "egress_cidrs" {
  type = "list"
}

variable "load_balancer_names" {
  type = "list"
  default = []
}

variable "minimum_instances" {
  default = 1
}
variable "maximum_instances" {
  default = 1
}
variable "desired_instances" {
  default = 1
}
