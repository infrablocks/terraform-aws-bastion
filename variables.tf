variable "region" {
  description = "The region into which to deploy the bastion."
}
variable "vpc_id" {
  description = "The ID of the VPC the bastion should be deployed into."
}
variable "subnet_ids" {
  description = "The IDs of the subnets the bastion should deploy into."
  type = "list"
}

variable "component" {
  description = "The component this network will contain."
}
variable "deployment_identifier" {
  description = "An identifier for this instantiation."
}

variable "ami" {
  description = "The ID of the AMI for the bastion instances."
}
variable "instance_type" {
  description = "The instance type of the bastion instances."
  default = "t2.nano"
}
variable "ssh_public_key_path" {
  description = "The absolute path of the SSH public key to use for bastion access."
}

variable "allowed_cidrs" {
  description = "The CIDRs that are allowed to access the bastion."
  type = "list"
}
variable "egress_cidrs" {
  description = "The CIDRs that are reachable from the bastion."
  type = "list"
}

variable "load_balancer_names" {
  description = "The load balancers to update on autoscaling events."
  type = "list"
  default = []
}

variable "minimum_instances" {
  description = "The minimum number of bastion instances."
  default = 1
}
variable "maximum_instances" {
  description = "The maximum number of bastion instances."
  default = 1
}
variable "desired_instances" {
  description = "The desired number of bastion instances."
  default = 1
}
