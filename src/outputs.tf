output "launch_configuration_name" {
  value = "${aws_launch_configuration.bastion.name}"
}

output "bastion_security_group_id" {
  value = "${aws_security_group.bastion.id}"
}

output "open_to_bastion_security_group_id" {
  value = "${aws_security_group.open_to_bastion.id}"
}
