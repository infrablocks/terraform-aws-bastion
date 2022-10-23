# frozen_string_literal: true

require 'spec_helper'

describe 'SSH from bastion security group' do
  let(:component) do
    var(role: :root, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end
  let(:vpc_id) do
    output(role: :prerequisites, name: 'vpc_id')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'create a security group' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'allow_ssh_from_bastion'
        ).once)
    end

    it 'includes the component and deployment identifier in the name' do
      name = "allow-ssh-from-bastion-#{component}-#{deployment_identifier}"
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'allow_ssh_from_bastion'
        )
              .with_attribute_value(:name, name))
    end

    it 'uses the provided VPC ID' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'allow_ssh_from_bastion'
        )
              .with_attribute_value(:vpc_id, vpc_id))
    end

    it 'allows inbound SSH connections' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'allow_ssh_from_bastion'
        )
              .with_attribute_value(
                [:ingress, 0],
                a_hash_including(
                  from_port: 22,
                  to_port: 22,
                  protocol: 'tcp'
                )
              ))
    end

    it 'adds component and deployment identifier tags' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'allow_ssh_from_bastion'
        )
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Component: component,
                  DeploymentIdentifier: deployment_identifier
                )
              ))
    end

    it 'adds a name tag' do
      name = "allow-ssh-from-bastion-#{component}-#{deployment_identifier}"
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'allow_ssh_from_bastion'
        )
              .with_attribute_value(:tags, a_hash_including(Name: name)))
    end

    it 'adds a role tag of bastion' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'allow_ssh_from_bastion'
        )
              .with_attribute_value(:tags, a_hash_including(Role: 'bastion')))
    end
  end
end
