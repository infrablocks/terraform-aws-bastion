module "base_network" {
  source  = "infrablocks/base-networking/aws"
  version = "3.0.0"

  region = var.region
  vpc_cidr = var.vpc_cidr
  availability_zones = var.availability_zones

  component = "${var.component}-net"
  deployment_identifier = var.deployment_identifier
  dependencies = var.dependencies

  private_zone_id = var.private_zone_id
}

module "classic_load_balancer" {
  source  = "infrablocks/classic-load-balancer/aws"
  version = "1.4.0-rc.1"

  vpc_id = module.base_network.vpc_id
  subnet_ids = module.base_network.public_subnet_ids

  domain_name = var.domain_name
  public_zone_id = var.public_zone_id
  private_zone_id = var.private_zone_id

  component = var.component
  deployment_identifier = var.deployment_identifier

  listeners = var.listeners
  access_control = var.access_control

  egress_cidrs = var.egress_cidrs

  health_check_target = var.health_check_target

  include_public_dns_record = var.include_public_dns_record
  include_private_dns_record = var.include_private_dns_record

  expose_to_public_internet = var.expose_to_public_internet
}
