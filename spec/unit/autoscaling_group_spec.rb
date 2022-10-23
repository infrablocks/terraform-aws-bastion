# frozen_string_literal: true

require 'spec_helper'

RSpec::Matchers.define :a_propagated_tag do |key, value|
  match do |tag|
    tag[:key] == key &&
      tag[:value] == value &&
      tag[:propagate_at_launch] == true
  end
end

describe 'autoscaling group' do
  let(:component) do
    var(role: :root, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end
  let(:load_balancer_name) do
    output(role: :prerequisites, name: 'load_balancer_name')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'creates an autoscaling group' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .once)
    end

    it 'includes the component in the name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .with_attribute_value(:name, match(/.*#{component}.*/)))
    end

    it 'includes the deployment identifier in the name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .with_attribute_value(
                :name, match(/.*#{deployment_identifier}.*/)
              ))
    end

    it 'uses the provided load balancer names' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .with_attribute_value(:load_balancers, [load_balancer_name]))
    end

    it 'uses a minimum size of 1' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .with_attribute_value(:min_size, 1))
    end

    it 'uses a maximum size of 1' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .with_attribute_value(:max_size, 1))
    end

    it 'uses a desired capacity of 1' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .with_attribute_value(:desired_capacity, 1))
    end

    it 'adds a name tag propagated at launch' do
      name = "bastion-#{component}-#{deployment_identifier}"
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .with_attribute_value(
                :tag, including(a_propagated_tag('Name', name))
              ))
    end

    it 'adds a component tag propagated at launch' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .with_attribute_value(
                :tag, including(a_propagated_tag('Component', component))
              ))
    end

    it 'adds a deployment identifier tag propagated at launch' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .with_attribute_value(
                :tag,
                including(a_propagated_tag(
                            'DeploymentIdentifier', deployment_identifier
                          ))
              ))
    end

    it 'adds a role tag of bastion propagated at launch' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .with_attribute_value(
                :tag, including(a_propagated_tag('Role', 'bastion'))
              ))
    end
  end

  describe 'when subnet IDs provided' do
    let(:private_subnet_ids) do
      output(role: :prerequisites, name: 'private_subnet_ids')
    end

    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.subnet_ids =
          output(role: :prerequisites, name: 'private_subnet_ids')
      end
    end

    it 'uses the provided subnet IDs as the VPC zone identifier' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_autoscaling_group')
              .with_attribute_value(:vpc_zone_identifier, private_subnet_ids))
    end
  end
end
