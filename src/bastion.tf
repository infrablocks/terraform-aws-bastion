data "aws_availability_zones" "all" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]

  name_regex = "^amzn-ami-hvm-\\d{4}\\.\\d{2}\\.\\d*"

  filter {
    name = "name"
    values = ["amzn-ami-hvm-*-gp2"]
  }
}

resource "aws_key_pair" "bastion" {
  key_name = "${var.component}-${var.deployment_identifier}"
  public_key = "${file(var.ssh_public_key_path)}"
}

resource "aws_launch_configuration" "bastion" {
  name_prefix = "${var.component}-${var.deployment_identifier}"
  image_id = "${coalesce(var.ami, data.aws_ami.amazon_linux.id)}"
  instance_type = "${var.instance_type}"
  key_name = "${aws_key_pair.bastion.key_name}"

  security_groups = [
    "${aws_security_group.bastion.id}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name = "${var.component}-${var.deployment_identifier}"

  vpc_zone_identifier = [
    "${coalescelist(var.subnet_ids, data.aws_availability_zones.all.names)}"
  ]

  launch_configuration = "${aws_launch_configuration.bastion.name}"

  load_balancers = ["${var.load_balancer_names}"]

  min_size = "${var.minimum_instances}"
  max_size = "${var.maximum_instances}"
  desired_capacity = "${var.desired_instances}"

  tag {
    key = "Name"
    value = "${var.component}-${var.deployment_identifier}"
    propagate_at_launch = true
  }

  tag{
    key = "Component"
    value = "${var.component}"
    propagate_at_launch = true
  }

  tag {
    key = "DeploymentIdentifier"
    value = "${var.deployment_identifier}"
    propagate_at_launch = true
  }

  tag{
    key = "Role"
    value = "bastion"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "bastion" {
  name = "${var.component}-${var.deployment_identifier}"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "${var.allowed_cidrs}"
    ]
  }

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "${var.egress_cidrs}"
    ]
  }
}

resource "aws_security_group" "open_to_bastion" {
  name = "open-to-bastion-${var.component}-${var.deployment_identifier}"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "open-to-bastion-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.bastion.id}"
    ]
  }
}
