# frozen_string_literal: true

require 'spec_helper'

describe 'key pair' do
  let(:component) do
    var(role: :root, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end
  let(:ssh_public_key_path) do
    var(role: :root, name: 'ssh_public_key_path')
  end
  let(:ssh_public_key) do
    File.read(ssh_public_key_path)
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'creates a key pair' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_key_pair')
              .once)
    end

    it 'includes the component and the deployment identifier in the key name' do
      key_name = "bastion-#{component}-#{deployment_identifier}"
      expect(@plan)
        .to(include_resource_creation(type: 'aws_key_pair')
              .with_attribute_value(:key_name, key_name))
    end

    it 'uses the provided public key' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_key_pair')
              .with_attribute_value(:public_key, ssh_public_key))
    end
  end
end
