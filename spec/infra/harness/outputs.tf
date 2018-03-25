output "launch_configuration_name" {
  value = "${module.bastion.launch_configuration_name}"
}

output "bastion_security_group_id" {
  value = "${module.bastion.bastion_security_group_id}"
}

output "allow_ssh_to_bastion_security_group_id" {
  value = "${module.bastion.allow_ssh_to_bastion_security_group_id}"
}

output "open_to_bastion_security_group_id" {
  value = "${module.bastion.open_to_bastion_security_group_id}"
}

output "allow_ssh_from_bastion_security_group_id" {
  value = "${module.bastion.allow_ssh_from_bastion_security_group_id}"
}
