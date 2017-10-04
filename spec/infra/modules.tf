module "base_network" {
  source = "git@github.com:infrablocks/terraform-aws-base-networking.git//src"

  vpc_cidr = "${var.vpc_cidr}"
  region = "${var.region}"
  availability_zones = "${var.availability_zones}"

  component = "${var.component}-net"
  deployment_identifier = "${var.deployment_identifier}"
  dependencies = "${var.dependencies}"

  bastion_ami = "${var.ami}"
  bastion_instance_type = "${var.instance_type}"
  bastion_ssh_public_key_path = "${var.ssh_public_key_path}"
  bastion_ssh_allow_cidrs = "${join(",", var.allowed_cidrs)}"

  domain_name = "${var.domain_name}"
  public_zone_id = "${var.public_zone_id}"
  private_zone_id = "${var.private_zone_id}"

  infrastructure_events_bucket = "${var.infrastructure_events_bucket}"
}

module "classic_load_balancer" {
  source = "git@github.com:infrablocks/terraform-aws-classic-load-balancer.git//src"

  region = "${var.region}"
  vpc_id = "${module.base_network.vpc_id}"
  subnet_ids = "${split(",", module.base_network.public_subnet_ids)}"

  domain_name = "${var.domain_name}"
  public_zone_id = "${var.public_zone_id}"
  private_zone_id = "${var.private_zone_id}"

  component = "${var.component}"
  deployment_identifier = "${var.deployment_identifier}"

  listeners = "${var.listeners}"
  access_control = "${var.access_control}"

  egress_cidrs = "${var.egress_cidrs}"

  health_check_target = "${var.health_check_target}"

  include_public_dns_record = "${var.include_public_dns_record}"
  include_private_dns_record = "${var.include_private_dns_record}"

  expose_to_public_internet = "${var.expose_to_public_internet}"
}

module "bastion" {
  source = "../../../src"

  region = "${var.region}"
  vpc_id = "${module.base_network.vpc_id}"
  subnet_ids = "${split(",", module.base_network.private_subnet_ids)}"

  component = "${var.component}"
  deployment_identifier = "${var.deployment_identifier}"

  ami = "${var.ami}"
  instance_type = "${var.instance_type}"

  ssh_public_key_path = "${var.ssh_public_key_path}"

  allowed_cidrs = "${var.allowed_cidrs}"
  egress_cidrs = "${var.egress_cidrs}"

  load_balancer_names = ["${module.classic_load_balancer.name}"]

  minimum_instances = "${var.minimum_instances}"
  maximum_instances = "${var.maximum_instances}"
  desired_instances = "${var.desired_instances}"
}
