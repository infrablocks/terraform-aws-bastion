variable "region" {}
variable "vpc_cidr" {}
variable "availability_zones" {
  type = list(string)
}

variable "component" {}
variable "deployment_identifier" {}
variable "dependencies" {
  type = list(string)
}

variable "domain_name" {}
variable "public_zone_id" {}
variable "private_zone_id" {}

variable "infrastructure_events_bucket" {}

variable "listeners" {
  type = list(object({
    lb_port: number,
    lb_protocol: string,
    instance_port: number,
    instance_protocol: string
    ssl_certificate_id: string
  }))
}
variable "access_control" {
  type = list(object({
    lb_port: number,
    instance_port: number
    allow_cidrs: list(string)
  }))
}

variable "health_check_target" {}

variable "egress_cidrs" {
  type = list(string)
}

variable "include_public_dns_record" {}
variable "include_private_dns_record" {}

variable "expose_to_public_internet" {}
