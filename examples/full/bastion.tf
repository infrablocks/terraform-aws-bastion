module "bastion" {
  source = "../../"

  vpc_id = module.base_network.vpc_id
  subnet_ids = module.base_network.private_subnet_ids

  component = var.component
  deployment_identifier = var.deployment_identifier

  ssh_public_key_path = var.ssh_public_key_path

  allowed_cidrs = var.allowed_cidrs
  egress_cidrs = var.egress_cidrs

  load_balancer_names = [
    module.classic_load_balancer.name
  ]
}
