# frozen_string_literal: true

require 'git'
require 'yaml'
require 'semantic'
require 'rake_terraform'
require 'rake_circle_ci'
require 'rake_github'
require 'rake_ssh'
require 'rake_gpg'
require 'securerandom'
require 'rspec/core/rake_task'

require_relative 'lib/configuration'
require_relative 'lib/version'

configuration = Configuration.new

def repo
  Git.open(Pathname.new('.'))
end

def latest_tag
  repo.tags.map do |tag|
    Semantic::Version.new(tag.name)
  end.max
end

task default: 'test:integration'

RakeTerraform.define_installation_tasks(
  path: File.join(Dir.pwd, 'vendor', 'terraform'),
  version: '1.0.11')

namespace :encryption do
  namespace :directory do
    task :ensure do
      FileUtils.mkdir_p('config/secrets/ci')
    end
  end

  namespace :passphrase do
    task generate: ["directory:ensure"] do
      File.open('config/secrets/ci/encryption.passphrase', 'w') do |f|
        f.write(SecureRandom.base64(36))
      end
    end
  end
end

namespace :keys do
  namespace :deploy do
    RakeSSH.define_key_tasks(
      path: 'config/secrets/ci/',
      comment: 'maintainers@infrablocks.io'
    )
  end

  namespace :bastion do
    RakeSSH.define_key_tasks(
      path: 'config/secrets/bastion/',
      comment: 'maintainers@infrablocks.io'
    )
  end

  namespace :secrets do
    namespace :gpg do
      RakeGPG.define_generate_key_task(
        output_directory: 'config/secrets/ci',
        name_prefix: 'gpg',
        owner_name: 'InfraBlocks Maintainers',
        owner_email: 'maintainers@infrablocks.io',
        owner_comment: 'terraform-aws-bastion CI Key')
    end

    task generate: ['gpg:generate']
  end
end

namespace :secrets do
  task regenerate: %w[
    encryption:passphrase:generate
    keys:deploy:generate
    keys:bastion:generate
    keys:secrets:generate
  ]
end

RakeCircleCI.define_project_tasks(
  namespace: :circle_ci,
  project_slug: 'github/infrablocks/terraform-aws-bastion'
) do |t|
  circle_ci_config =
    YAML.load_file('config/secrets/circle_ci/config.yaml')

  t.api_token = circle_ci_config['circle_ci_api_token']
  t.environment_variables = {
    ENCRYPTION_PASSPHRASE:
      File.read('config/secrets/ci/encryption.passphrase')
          .chomp,
    CIRCLECI_API_KEY:
      YAML.load_file(
        'config/secrets/circle_ci/config.yaml')['circle_ci_api_token']
  }
  t.checkout_keys = []
  t.ssh_keys = [
    {
      hostname: 'github.com',
      private_key: File.read('config/secrets/ci/ssh.private')
    }
  ]
end

RakeGithub.define_repository_tasks(
  namespace: :github,
  repository: 'infrablocks/terraform-aws-bastion',
) do |t, args|
  github_config =
    YAML.load_file('config/secrets/github/config.yaml')

  t.access_token = github_config['github_personal_access_token']
  t.deploy_keys = [
    {
      title: 'CircleCI',
      public_key: File.read('config/secrets/ci/ssh.public')
    }
  ]
  t.branch_name = args.branch_name
  t.commit_message = args.commit_message
end

namespace :pipeline do
  task prepare: %i[
    circle_ci:project:follow
    circle_ci:env_vars:ensure
    circle_ci:checkout_keys:ensure
    circle_ci:ssh_keys:ensure
    github:deploy_keys:ensure
  ]
end

namespace :test do
  RSpec::Core::RakeTask.new(integration: ['terraform:ensure']) do
    plugin_cache_directory =
      "#{Paths.project_root_directory}/vendor/terraform/plugins"

    mkdir_p(plugin_cache_directory)

    ENV['TF_PLUGIN_CACHE_DIR'] = plugin_cache_directory
    ENV['AWS_REGION'] = configuration.region
  end
end

namespace :deployment do
  namespace :prerequisites do
    RakeTerraform.define_command_tasks(
      configuration_name: 'prerequisites',
      argument_names: [:deployment_identifier]
    ) do |t, args|
      deployment_configuration =
        configuration.for(:prerequisites, args)

      t.source_directory = deployment_configuration.source_directory
      t.work_directory = deployment_configuration.work_directory

      t.state_file = deployment_configuration.state_file
      t.vars = deployment_configuration.vars
    end
  end

  namespace :harness do
    RakeTerraform.define_command_tasks(
      configuration_name: 'harness',
      argument_names: [:deployment_identifier]
    ) do |t, args|
      deployment_configuration = configuration.for(:harness, args)

      t.source_directory = deployment_configuration.source_directory
      t.work_directory = deployment_configuration.work_directory

      t.state_file = deployment_configuration.state_file
      t.vars = deployment_configuration.vars
    end
  end
end

namespace :version do
  task :bump, [:type] do |_, args|
    next_tag = latest_tag.send("#{args.type}!")
    repo.add_tag(next_tag.to_s)
    repo.push('origin', 'main', tags: true)
    puts "Bumped version to #{next_tag}."
  end

  task :release do
    next_tag = latest_tag.release!
    repo.add_tag(next_tag.to_s)
    repo.push('origin', 'main', tags: true)
    puts "Released version #{next_tag}."
  end
end
