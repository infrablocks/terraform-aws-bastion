locals {
  # default for cases when `null` value provided, meaning "use default"
  instance_type               = var.instance_type == null ? "t4g.nano" : var.instance_type
  minimum_instances           = var.minimum_instances == null ? 1 : var.minimum_instances
  maximum_instances           = var.maximum_instances == null ? 1 : var.maximum_instances
  desired_instances           = var.desired_instances == null ? 1 : var.desired_instances
  associate_public_ip_address = var.associate_public_ip_address == null ? false : var.associate_public_ip_address
}
