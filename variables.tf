variable "vpc_id" {
  description = "The ID of the VPC the bastion should be deployed into."
  type = string
}
variable "subnet_ids" {
  description = "The IDs of the subnets the bastion should deploy into."
  type = list(string)
}

variable "component" {
  description = "The name of this component."
  type = string
}
variable "deployment_identifier" {
  description = "An identifier for this instantiation."
  type = string
}

variable "ami" {
  description = "The ID of the AMI for the bastion instances."
  type = string
}
variable "instance_type" {
  description = "The instance type of the bastion instances."
  type = string
  default = "t2.nano"
}
variable "ssh_public_key_path" {
  description = "The absolute path of the SSH public key to use for bastion access."
  type = string
}

variable "allowed_cidrs" {
  description = "The CIDRs that are allowed to access the bastion."
  type = list(string)
}
variable "egress_cidrs" {
  description = "The CIDRs that are reachable from the bastion."
  type = list(string)
}

variable "load_balancer_names" {
  description = "The names of the load balancers to update on autoscaling events."
  type = list(string)
  default = []
}

variable "minimum_instances" {
  description = "The minimum number of bastion instances."
  type = number
  default = 1
}
variable "maximum_instances" {
  description = "The maximum number of bastion instances."
  type = number
  default = 1
}
variable "desired_instances" {
  description = "The desired number of bastion instances."
  type = number
  default = 1
}
