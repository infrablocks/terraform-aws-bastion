output "launch_configuration_name" {
  description = "The name of the launch configuration for bastion instances."
  value = aws_launch_configuration.bastion.name
}

output "allow_ssh_to_bastion_security_group_id" {
  description = "The ID of the security group that allows ssh access to the bastion."
  value = aws_security_group.allow_ssh_to_bastion.id
}

output "allow_ssh_from_bastion_security_group_id" {
  description = "The ID of the security group that allows ssh access from the bastion."
  value = aws_security_group.allow_ssh_from_bastion.id
}
