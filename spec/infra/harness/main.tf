data "terraform_remote_state" "prerequisites" {
  backend = "local"

  config {
    path = "${path.module}/../../../../state/prerequisites.tfstate"
  }
}

module "bastion" {
  source = "../../../../"

  region = "${var.region}"
  vpc_id = "${data.terraform_remote_state.prerequisites.vpc_id}"
  subnet_ids = "${split(",", data.terraform_remote_state.prerequisites.private_subnet_ids)}"

  component = "${var.component}"
  deployment_identifier = "${var.deployment_identifier}"

  ami = "${var.ami}"
  instance_type = "${var.instance_type}"

  ssh_public_key_path = "${var.ssh_public_key_path}"

  allowed_cidrs = "${var.allowed_cidrs}"
  egress_cidrs = "${var.egress_cidrs}"

  load_balancer_names = ["${data.terraform_remote_state.prerequisites.load_balancer_name}"]

  minimum_instances = "${var.minimum_instances}"
  maximum_instances = "${var.maximum_instances}"
  desired_instances = "${var.desired_instances}"
}
