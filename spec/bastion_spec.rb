require 'spec_helper'
require 'socket'
require 'net/ssh'

describe 'bastion' do
  context 'launch configuration' do
    subject {
      launch_configuration(
          output_for(:harness, 'launch_configuration_name'))
    }

    it { should exist }
    its(:instance_type) { should eq(vars.instance_type) }
    its(:image_id) { should eq(vars.ami) }

    its(:key_name) do
      should eq("bastion-#{vars.component}-#{vars.deployment_identifier}")
    end

    it {
      should have_security_group(
          "allow-ssh-to-bastion-#{vars.component}-#{vars.deployment_identifier}")
    }

    it 'has a name containing the component and deployment_identifier' do
      launch_configuration_name =
          output_for(:harness, 'launch_configuration_name')

      expect(launch_configuration_name)
          .to(match(/#{vars.component}/))
      expect(launch_configuration_name)
          .to(match(/#{vars.deployment_identifier}/))
    end
  end

  context 'autoscaling group' do
    subject {
      autoscaling_group("#{vars.component}-#{vars.deployment_identifier}")
    }

    it { should exist }

    its(:min_size) { should eq(vars.minimum_instances.to_i) }
    its(:max_size) { should eq(vars.maximum_instances.to_i) }
    its(:desired_capacity) { should eq(vars.desired_instances.to_i) }

    its(:launch_configuration_name) do
      should eq(output_for(:harness, 'launch_configuration_name'))
    end

    it 'uses the provided subnets' do
      expect(subject.vpc_zone_identifier.split(','))
          .to(contain_exactly(
              *output_for(:prerequisites, 'private_subnet_ids')))
    end

    it 'uses the provided load balancer names' do
      expect(subject.load_balancer_names)
          .to(contain_exactly(output_for(:prerequisites, 'load_balancer_name')))
    end

    it { should have_tag('Name')
        .value("bastion-#{vars.component}-#{vars.deployment_identifier}") }
    it { should have_tag('Component')
        .value(vars.component) }
    it { should have_tag('DeploymentIdentifier')
        .value(vars.deployment_identifier) }
    it { should have_tag('Role')
        .value('bastion') }
  end

  context 'allow-ssh-to-bastion security group' do
    subject { security_group(
        output_for(:harness, 'allow_ssh_to_bastion_security_group_id')) }

    it { should exist }

    it { should have_tag('Name')
        .value("allow-ssh-to-bastion-#{vars.component}-#{vars.deployment_identifier}") }
    it { should have_tag('Component')
        .value(vars.component) }
    it { should have_tag('DeploymentIdentifier')
        .value(vars.deployment_identifier) }

    its(:vpc_id) { should eq(output_for(:prerequisites, 'vpc_id')) }

    it 'allows inbound SSH for each supplied CIDR' do
      allowed_cidrs = vars.allowed_cidrs
      allowed_cidrs.each do |cidr|
        ingress_rule = subject.ip_permissions.find do |perm|
          perm.ip_ranges.map(&:cidr_ip).include?(cidr)
        end

        expect(ingress_rule.from_port).to(eq(22))
        expect(ingress_rule.to_port).to(eq(22))
        expect(ingress_rule.ip_protocol).to(eq('tcp'))
      end

      expect(subject.inbound_rule_count).to(eq(allowed_cidrs.count))
    end

    it 'allows outbound SSH for each supplied CIDR' do
      egress_cidrs = vars.egress_cidrs
      egress_cidrs.each do |cidr|
        egress_rule = subject.ip_permissions_egress.find do |perm|
          perm.ip_ranges.map(&:cidr_ip).include?(cidr)
        end

        expect(egress_rule.from_port).to(eq(22))
        expect(egress_rule.to_port).to(eq(22))
        expect(egress_rule.ip_protocol).to(eq('tcp'))
      end

      expect(subject.outbound_rule_count).to(eq(egress_cidrs.count))
    end
  end

  context 'allow-ssh-from-bastion security group' do
    subject {
      security_group(
          output_for(:harness, 'allow_ssh_from_bastion_security_group_id'))
    }

    let(:bastion_security_group) {
      security_group(
          output_for(:harness, 'allow_ssh_to_bastion_security_group_id'))
    }

    it { should exist }

    it { should have_tag('Name')
        .value("allow-ssh-from-bastion-#{vars.component}-#{vars.deployment_identifier}") }
    it { should have_tag('Component')
        .value(vars.component) }
    it { should have_tag('DeploymentIdentifier')
        .value(vars.deployment_identifier) }

    its(:vpc_id) { should eq(output_for(:prerequisites, 'vpc_id')) }

    it 'allows inbound SSH from the bastion' do
      permission = subject.ip_permissions.find do |permission|
        permission.user_id_group_pairs.find do |pair|
          pair.group_id == bastion_security_group.id
        end
      end

      expect(permission).not_to(be(nil))
      expect(permission.from_port).to(eq(22))
      expect(permission.to_port).to(eq(22))
      expect(permission.ip_protocol).to(eq('tcp'))
    end
  end

  context 'connectivity' do
    it 'is reachable using the corresponding private SSH key' do
      attempts = 10
      interval = 30
      succeeded = false
      exception = nil

      expect {
        while !succeeded && attempts > 0
          begin
            user = configuration.for(:harness).connection[:user]
            ssh_private_key_path =
                configuration.for(:harness).connection[:ssh_private_key_path]
            domain_name = configuration.for(:harness).connection[:domain_name]
            address =
                "#{vars.component}-#{vars.deployment_identifier}.#{domain_name}"
            ssh = Net::SSH.start(
                address,
                user,
                options = {
                    keys: ssh_private_key_path,
                    verbose: :info,
                    paranoid: false
                })
            ssh.exec!('ls -al')
            ssh.close
            succeeded = true
          rescue Exception => e
            attempts -= 1
            exception = e
            sleep interval
          end
        end

        unless succeeded
          raise exception
        end
      }.not_to raise_error
    end
  end
end