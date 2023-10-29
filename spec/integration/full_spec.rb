# frozen_string_literal: true

require 'spec_helper'
require 'socket'
require 'net/ssh'

describe 'full example' do
  let(:component) do
    var(role: :full, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :full, name: 'deployment_identifier')
  end
  let(:vpc_id) do
    output(role: :full, name: 'vpc_id')
  end

  before(:context) do
    apply(role: :full)
  end

  after(:context) do
    destroy(
      role: :full,
      only_if: -> { !ENV['FORCE_DESTROY'].nil? || ENV['SEED'].nil? }
    )
  end

  describe 'launch configuration' do
    subject(:created_launch_configuration) do
      launch_configuration(
        output(role: :full, name: 'launch_configuration_name')
      )
    end

    let(:latest_ami) do
      ec2_client
        .describe_images(
          owners: ['amazon'],
          filters: [{ name: 'name', values: ['amzn2-ami-ecs-hvm-*-arm64-ebs'] }]
        )
        .images
        .max_by(&:creation_date)
    end

    it { is_expected.to exist }
    its(:instance_type) { is_expected.to eq('t4g.nano') }
    its(:image_id) { is_expected.to eq(latest_ami.image_id) }

    its(:key_name) do
      is_expected.to eq("bastion-#{component}-#{deployment_identifier}")
    end

    it {
      expect(created_launch_configuration)
        .to(have_security_group(
              "allow-ssh-to-bastion-#{component}-#{deployment_identifier}"
            ))
    }

    # rubocop:disable RSpec/MultipleExpectations
    it 'has a name containing the component and deployment_identifier' do
      launch_configuration_name =
        output(role: :full, name: 'launch_configuration_name')

      expect(launch_configuration_name)
        .to(match(/#{component}/))
      expect(launch_configuration_name)
        .to(match(/#{deployment_identifier}/))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'autoscaling group' do
    subject(:created_asg) do
      autoscaling_group("#{component}-#{deployment_identifier}")
    end

    let(:load_balancer_name) do
      output(role: :full, name: 'load_balancer_name')
    end
    let(:private_subnet_ids) do
      output(role: :full, name: 'private_subnet_ids')
    end
    let(:launch_configuration_name) do
      output(role: :full, name: 'launch_configuration_name')
    end

    it { is_expected.to exist }

    its(:min_size) { is_expected.to eq(1.to_i) }
    its(:max_size) { is_expected.to eq(1.to_i) }
    its(:desired_capacity) { is_expected.to eq(1.to_i) }

    its(:launch_configuration_name) do
      is_expected.to eq(launch_configuration_name)
    end

    it 'uses the provided subnets' do
      expect(created_asg.vpc_zone_identifier.split(','))
        .to(match_array(private_subnet_ids))
    end

    it 'uses the provided load balancer names' do
      expect(created_asg.load_balancer_names)
        .to(contain_exactly(load_balancer_name))
    end

    it {
      expect(created_asg).to have_tag('Name')
        .value("bastion-#{component}-#{deployment_identifier}")
    }

    it {
      expect(created_asg).to have_tag('Component')
        .value(component)
    }

    it {
      expect(created_asg).to have_tag('DeploymentIdentifier')
        .value(deployment_identifier)
    }

    it {
      expect(created_asg).to have_tag('Role')
        .value('bastion')
    }
  end

  describe 'allow-ssh-to-bastion security group' do
    subject(:inbound_security_group) do
      security_group(allow_ssh_to_bastion_security_group_id)
    end

    let(:allow_ssh_to_bastion_security_group_id) do
      output(role: :full, name: 'allow_ssh_to_bastion_security_group_id')
    end
    let(:allowed_cidrs) do
      var(role: :full, name: 'allowed_cidrs')
    end
    let(:egress_cidrs) do
      var(role: :full, name: 'egress_cidrs')
    end
    let(:security_group_name) do
      "allow-ssh-to-bastion-#{component}-#{deployment_identifier}"
    end

    it { is_expected.to exist }

    it { is_expected.to have_tag('Name').value(security_group_name) }
    it { is_expected.to have_tag('Component').value(component) }

    it {
      expect(inbound_security_group)
        .to(have_tag('DeploymentIdentifier').value(deployment_identifier))
    }

    its(:vpc_id) { is_expected.to eq(vpc_id) }

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows inbound SSH for each supplied CIDR' do
      allowed_cidrs.each do |cidr|
        ingress_rule = inbound_security_group
                       .ip_permissions
                       .find do |perm|
          perm.ip_ranges.map(&:cidr_ip).include?(cidr)
        end

        expect(ingress_rule.from_port).to(eq(22))
        expect(ingress_rule.to_port).to(eq(22))
        expect(ingress_rule.ip_protocol).to(eq('tcp'))
      end

      expect(inbound_security_group.inbound_rule_count)
        .to(eq(allowed_cidrs.count))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows outbound SSH for each supplied CIDR' do
      egress_cidrs.each do |cidr|
        egress_rule = inbound_security_group
                      .ip_permissions_egress
                      .find do |perm|
          perm.ip_ranges.map(&:cidr_ip).include?(cidr)
        end

        expect(egress_rule.from_port).to(eq(22))
        expect(egress_rule.to_port).to(eq(22))
        expect(egress_rule.ip_protocol).to(eq('tcp'))
      end

      expect(inbound_security_group.outbound_rule_count)
        .to(eq(egress_cidrs.count))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'allow-ssh-from-bastion security group' do
    subject(:outbound_security_group) do
      security_group(allow_ssh_from_bastion_security_group_id)
    end

    let(:allow_ssh_from_bastion_security_group_id) do
      output(role: :full, name: 'allow_ssh_from_bastion_security_group_id')
    end
    let(:bastion_security_group) do
      security_group(allow_ssh_to_bastion_security_group_id)
    end
    let(:allow_ssh_to_bastion_security_group_id) do
      output(role: :full, name: 'allow_ssh_to_bastion_security_group_id')
    end
    let(:security_group_name) do
      "allow-ssh-from-bastion-#{component}-#{deployment_identifier}"
    end

    it { is_expected.to exist }

    it { is_expected.to have_tag('Name').value(security_group_name) }
    it { is_expected.to have_tag('Component').value(component) }

    it {
      expect(outbound_security_group)
        .to(have_tag('DeploymentIdentifier').value(deployment_identifier))
    }

    its(:vpc_id) { is_expected.to eq(vpc_id) }

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows inbound SSH from the bastion' do
      permission = outbound_security_group
                   .ip_permissions
                   .find do |perm|
        perm.user_id_group_pairs.find do |pair|
          pair.group_id == bastion_security_group.id
        end
      end

      expect(permission).not_to(be_nil)
      expect(permission.from_port).to(eq(22))
      expect(permission.to_port).to(eq(22))
      expect(permission.ip_protocol).to(eq('tcp'))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'connectivity' do
    it 'is reachable using the corresponding private SSH key' do
      attempts = 10
      interval = 30
      succeeded = false
      exception = nil

      expect do
        while !succeeded && attempts > 0
          begin
            user = 'ec2-user'
            ssh_private_key_path = 'config/secrets/bastion/ssh.private'
            domain_name = var(role: :full, name: 'domain_name')
            address = "#{component}-#{deployment_identifier}.#{domain_name}"
            ssh = Net::SSH.start(
              address,
              user,
              {
                keys: ssh_private_key_path,
                verbose: :info,
                paranoid: false
              }
            )
            ssh.exec!('ls -al')
            ssh.close
            succeeded = true
          rescue StandardError => e
            attempts -= 1
            exception = e
            sleep interval
          end
        end

        raise exception unless succeeded
      end.not_to raise_error
    end
  end
end
