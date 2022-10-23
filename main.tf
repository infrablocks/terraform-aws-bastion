data "aws_availability_zones" "all" {}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-ecs-hvm-*-arm64-ebs"]
  }
}

resource "aws_key_pair" "bastion" {
  key_name = "bastion-${var.component}-${var.deployment_identifier}"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_launch_configuration" "bastion" {
  name_prefix = "${var.component}-${var.deployment_identifier}"
  image_id = coalesce(var.ami, data.aws_ami.amazon_linux_2.id)
  instance_type = local.instance_type
  key_name = aws_key_pair.bastion.key_name
  associate_public_ip_address = local.associate_public_ip_address

  security_groups = [
    aws_security_group.allow_ssh_to_bastion.id
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name = "${var.component}-${var.deployment_identifier}"

  vpc_zone_identifier = coalescelist(var.subnet_ids, data.aws_availability_zones.all.names)

  launch_configuration = aws_launch_configuration.bastion.name

  load_balancers = var.load_balancer_names

  min_size = local.minimum_instances
  max_size = local.maximum_instances
  desired_capacity = local.desired_instances

  tag {
    key = "Name"
    value = "bastion-${var.component}-${var.deployment_identifier}"
    propagate_at_launch = true
  }

  tag {
    key = "Component"
    value = var.component
    propagate_at_launch = true
  }

  tag {
    key = "DeploymentIdentifier"
    value = var.deployment_identifier
    propagate_at_launch = true
  }

  tag {
    key = "Role"
    value = "bastion"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "allow_ssh_to_bastion" {
  name = "allow-ssh-to-bastion-${var.component}-${var.deployment_identifier}"
  vpc_id = var.vpc_id

  tags = {
    Name = "allow-ssh-to-bastion-${var.component}-${var.deployment_identifier}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
    Role = "bastion"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.egress_cidrs
  }
}

resource "aws_security_group" "allow_ssh_from_bastion" {
  name = "allow-ssh-from-bastion-${var.component}-${var.deployment_identifier}"
  vpc_id = var.vpc_id

  tags = {
    Name = "allow-ssh-from-bastion-${var.component}-${var.deployment_identifier}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
    Role = "bastion"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [
      aws_security_group.allow_ssh_to_bastion.id
    ]
  }
}
