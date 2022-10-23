# frozen_string_literal: true

require 'spec_helper'

describe 'launch configuration' do
  let(:component) do
    var(role: :root, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'creates a launch configuration' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_launch_configuration')
              .once)
    end

    it 'includes the component in the name prefix' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_launch_configuration')
              .with_attribute_value(:name_prefix, match(/.*#{component}.*/)))
    end

    it 'includes the deployment identifier in the name prefix' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_launch_configuration')
              .with_attribute_value(
                :name_prefix, match(/.*#{deployment_identifier}.*/)
              ))
    end

    it 'uses an instance type of t4g.nano' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_launch_configuration')
              .with_attribute_value(:instance_type, 't4g.nano'))
    end

    it 'does not associate a public IP address' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_launch_configuration')
              .with_attribute_value(:associate_public_ip_address, false))
    end
  end

  describe 'when AMI is provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.ami = 'ami-12345678'
      end
    end

    it 'uses the provided AMI ID as the image ID' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_launch_configuration')
              .with_attribute_value(:image_id, 'ami-12345678'))
    end
  end
end
