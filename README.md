Terraform AWS Bastion
=====================

[![Version](https://img.shields.io/github/v/tag/infrablocks/terraform-aws-bastion?label=version&sort=semver)](https://github.com/infrablocks/terraform-aws-bastion/tags)
[![Build Pipeline](https://img.shields.io/circleci/build/github/infrablocks/terraform-aws-bastion/main?label=build-pipeline)](https://app.circleci.com/pipelines/github/infrablocks/terraform-aws-bastion?filter=all)
[![Maintainer](https://img.shields.io/badge/maintainer-go--atomic.io-red)](https://go-atomic.io)

A Terraform module for deploying a supervised bastion into a base network in
AWS.

The bastion requires:

* An existing base network
* One or more existing load balancers

The bastion consists of:

* An autoscaling group and launch configuration for bastion instances
  configured with the supplied SSH key updating the supplied load balancers.
* A security group allowing SSH access to the bastion from the load balancers.
* A security group allowing SSH access from the bastion, for assigning to
  protected instances.

![Diagram of infrastructure managed by this module](https://raw.githubusercontent.com/infrablocks/terraform-aws-bastion/main/docs/architecture.png)

Usage
-----

To use the module, include something like the following in your Terraform
configuration:

```terraform
module "bastion" {
  source  = "infrablocks/bastion/aws"
  version = "3.0.0"

  vpc_id     = "vpc-fb7dc365"
  subnet_ids = ["subnet-ae4533c4", "subnet-443e6b12"]

  component             = "important-component"
  deployment_identifier = "production"

  ami           = "ami-bb373ddf"
  instance_type = "t2.micro"

  ssh_public_key_path = "~/.ssh/id_rsa.pub"

  allowed_cidrs = ["100.10.10.0/24", "200.20.0.0/16"]
  egress_cidrs  = "10.0.0.0/16"

  load_balancer_names = ["lb-12345678"]

  minimum_instances = 1
  maximum_instances = 3
  desired_instances = 2
}
```

As mentioned above, the bastion deploys into an existing base network.
Whilst the base network can be created using any mechanism you like, the
[AWS Base Networking](https://github.com/infrablocks/terraform-aws-base-networking)
module will create everything you need. See the
[docs](https://github.com/infrablocks/terraform-aws-base-networking/blob/main/README.md)
for usage instructions.

Similarly, the bastion is reachable through one or more load balancers.
Whilst the load balancers can be created using any mechanism you like, the
[AWS Classic Load Balancer](https://github.com/infrablocks/terraform-aws-classic-load-balancer)
module will create everything you need. See the
[docs](https://github.com/infrablocks/terraform-aws-classic-load-balancer/blob/main/README.md)
for usage instructions.

See the
[Terraform registry entry](https://registry.terraform.io/modules/infrablocks/bastion/aws/latest)
for more details.

### Inputs

| Name                          | Description                                                                |   Default   | Required |
|-------------------------------|----------------------------------------------------------------------------|:-----------:|:--------:|
| `vpc_id`                      | The ID of the VPC the bastion should be deployed into.                     |      -      |   Yes    |
| `subnet_ids`                  | The IDs of the subnets the bastion should deploy into.                     |      -      |   Yes    |
| `component`                   | The name of this component.                                                |      -      |   Yes    |
| `deployment_identifier`       | An identifier for this instantiation.                                      |      -      |   Yes    |
| `ami`                         | The ID of the AMI for the bastion instances.                               |      -      |   Yes    |
| `instance_type`               | The instance type of the bastion instances.                                | `"t2.nano"` |    No    |
| `ssh_public_key_path`         | The absolute path of the SSH public key to use for bastion access.         |      -      |   Yes    |
| `allowed_cidrs`               | A list of CIDRs that are allowed to access the bastion.                    |      -      |   Yes    |
| `egress_cidrs`                | A list of CIDRs that are reachable from the bastion.                       |      -      |   Yes    |
| `load_balancer_names`         | The names of the load balancers to update on autoscaling events.           |    `[]`     |    No    |
| `minimum_instances`           | The minimum number of bastion instances.                                   |     `1`     |    No    |
| `maximum_instances`           | The maximum number of bastion instances.                                   |     `1`     |    No    |
| `desired_instances`           | The desired number of bastion instances.                                   |     `1`     |    No    |
| `associate_public_ip_address` | Whether or not to associate a public IP address with an instance in a VPC. |   `false`   |    No    |

### Outputs

| Name                                       | Description                                                           |
|--------------------------------------------|-----------------------------------------------------------------------|
| `launch_configuration_name`                | The name of the launch configuration for bastion instances.           |
| `allow_ssh_to_bastion_security_group_id`   | The ID of the security group that allows ssh access to the bastion.   |
| `allow_ssh_from_bastion_security_group_id` | The ID of the security group that allows ssh access from the bastion. |

### Compatibility

This module is compatible with Terraform versions greater than or equal to
Terraform 1.0 and Terraform AWS provider versions greater than or equal to 3.29.

Development
-----------

### Machine Requirements

In order for the build to run correctly, a few tools will need to be installed
on your development machine:

* Ruby (3.1)
* Bundler
* git
* git-crypt
* gnupg
* direnv
* aws-vault

#### Mac OS X Setup

Installing the required tools is best managed by [homebrew](http://brew.sh).

To install homebrew:

```shell
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then, to install the required tools:

```shell
# ruby
brew install rbenv
brew install ruby-build
echo 'eval "$(rbenv init - bash)"' >> ~/.bash_profile
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
eval "$(rbenv init -)"
rbenv install 3.1.1
rbenv rehash
rbenv local 3.1.1
gem install bundler

# git, git-crypt, gnupg
brew install git
brew install git-crypt
brew install gnupg

# aws-vault
brew cask install

# direnv
brew install direnv
echo "$(direnv hook bash)" >> ~/.bash_profile
echo "$(direnv hook zsh)" >> ~/.zshrc
eval "$(direnv hook $SHELL)"

direnv allow <repository-directory>
```

### Running the build

Running the build requires an AWS account and AWS credentials. You are free to
configure credentials however you like as long as an access key ID and secret
access key are available. These instructions utilise
[aws-vault](https://github.com/99designs/aws-vault) which makes credential
management easy and secure.

To run the full build, including unit and integration tests, execute:

```shell
aws-vault exec <profile> -- ./go
```

To run the unit tests, execute:

```shell
aws-vault exec <profile> -- ./go test:unit
```

To run the integration tests, execute:

```shell
aws-vault exec <profile> -- ./go test:integration
```

To provision the module prerequisites:

```shell
aws-vault exec <profile> -- ./go deployment:prerequisites:provision[<deployment_identifier>]
```

To provision the module contents:

```shell
aws-vault exec <profile> -- ./go deployment:root:provision[<deployment_identifier>]
```

To destroy the module contents:

```shell
aws-vault exec <profile> -- ./go deployment:root:destroy[<deployment_identifier>]
```

To destroy the module prerequisites:

```shell
aws-vault exec <profile> -- ./go deployment:prerequisites:destroy[<deployment_identifier>]
```

Configuration parameters can be overridden via environment variables. For
example, to run the unit tests with a seed of `"testing"`, execute:

```shell
SEED=testing aws-vault exec <profile> -- ./go test:unit
```

When a seed is provided via an environment variable, infrastructure will not be
destroyed at the end of test execution. This can be useful during development
to avoid lengthy provision and destroy cycles.

To subsequently destroy unit test infrastructure for a given seed:

```shell
FORCE_DESTROY=yes SEED=testing aws-vault exec <profile> -- ./go test:unit
```

### Common Tasks

#### Generating an SSH key pair

To generate an SSH key pair:

```shell
ssh-keygen -m PEM -t rsa -b 4096 -C integration-test@example.com -N '' -f config/secrets/keys/bastion/ssh
```

#### Generating a self-signed certificate

To generate a self signed certificate:

```shell
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
```

To decrypt the resulting key:

```shell
openssl rsa -in key.pem -out ssl.key
```

#### Managing CircleCI keys

To encrypt a GPG key for use by CircleCI:

```shell
openssl aes-256-cbc \
  -e \
  -md sha1 \
  -in ./config/secrets/ci/gpg.private \
  -out ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

To check decryption is working correctly:

```shell
openssl aes-256-cbc \
  -d \
  -md sha1 \
  -in ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

Contributing
------------

Bug reports and pull requests are welcome on GitHub at
https://github.com/infrablocks/terraform-aws-bastion.
This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

License
-------

The library is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
