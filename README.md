Terraform AWS Bastion
=====================

[![CircleCI](https://circleci.com/gh/infrablocks/terraform-aws-bastion.svg?style=svg)](https://circleci.com/gh/infrablocks/terraform-aws-bastion)

A Terraform module for deploying a supervised bastion into a base network in 
AWS.

The bastion requires:
* An existing base network
* One or more existing load balancers

The bastion consists of:
* An autoscaling group and launch configuration for bastion instances 
  configured with the supplied SSH key updating the supplied load balancers.
* A security group allowing access to the bastion from the load balancers.
* A security group open to the bastion for use on protected instances.

![Diagram of infrastructure managed by this module](https://raw.githubusercontent.com/infrablocks/terraform-aws-bastion/master/docs/architecture.png)

Usage
-----

To use the module, include something like the following in your terraform configuration:

```hcl-terraform
module "bastion" {
  source  = "infrablocks/bastion/aws"
  version = "0.1.2"
  
  region = "eu-west-2"
  vpc_id = "vpc-fb7dc365"
  subnet_ids = "subnet-ae4533c4,subnet-443e6b12"
  
  component = "important-component"
  deployment_identifier = "production"
  
  ami = "ami-bb373ddf"
  instance_type = "t2.micro"
  
  ssh_public_key_path = "~/.ssh/id_rsa.pub"
  
  allowed_cidrs = "100.10.10.0/24,200.20.0.0/16"
  egress_cidrs = "10.0.0.0/16"
  
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
[docs](https://github.com/infrablocks/terraform-aws-base-networking/blob/master/README.md)
for usage instructions.

Similarly, the bastion is reachable through one or more load balancers.
Whilst the load balancers can be created using any mechanism you like, the
[AWS Classic Load Balancer](https://github.com/infrablocks/terraform-aws-classic-load-balancer)
module will create everything you need. See the 
[docs](https://github.com/infrablocks/terraform-aws-classic-load-balancer/blob/master/README.md)
for usage instructions.


### Inputs

| Name                  | Description                                                       | Default | Required |
|-----------------------|-------------------------------------------------------------------|:-------:|:--------:|
| region                | The region into which to deploy the bastion                       | -       | yes      |
| vpc_id                | The ID of the VPC the bastion should be deployed into             | -       | yes      |
| subnet_ids            | The IDs of the subnets the bastion should deploy into             | -       | yes      |
| component             | The name of this component                                        | -       | yes      |
| deployment_identifier | An identifier for this instantiation                              | -       | yes      |
| ami                   | The ID of the AMI for the bastion instances                       | -       | yes      |
| instance_type         | The instance type of the bastion instances                        | t2.nano | yes      |
| ssh_public_key_path   | The absolute path of the SSH public key to use for bastion access | -       | yes      |
| allowed_cidrs         | The CIDRs that are allowed to access the bastion                  | -       | yes      |
| egress_cidrs          | The CIDRs that are reachable from the bastion                     | -       | yes      |
| load_balancer_names   | The names of the load balancers to update on autoscaling events   | -       | yes      |
| minimum_instances     | The minimum number of bastion instances                           | -       | yes      |
| maximum_instances     | The maximum number of bastion instances                           | -       | yes      |
| desired_instances     | The desired number of bastion instances                           | yes     | yes      |


### Outputs

| Name                              | Description                                                   |
|-----------------------------------|---------------------------------------------------------------|
| launch_configuration_name         | The name of the launch configuration for bastion instances    |
| bastion_security_group_id         | The ID of the bastion's security group                        |
| open_to_bastion_security_group_id | The ID of the security group allowing access from the bastion |


Development
-----------

### Machine Requirements

In order for the build to run correctly, a few tools will need to be installed on your
development machine:

* Ruby (2.3.1)
* Bundler
* git
* git-crypt
* gnupg
* direnv

#### Mac OS X Setup

Installing the required tools is best managed by [homebrew](http://brew.sh).

To install homebrew:

```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then, to install the required tools:

```
# ruby
brew install rbenv
brew install ruby-build
echo 'eval "$(rbenv init - bash)"' >> ~/.bash_profile
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
eval "$(rbenv init -)"
rbenv install 2.3.1
rbenv rehash
rbenv local 2.3.1
gem install bundler

# git, git-crypt, gnupg
brew install git
brew install git-crypt
brew install gnupg

# direnv
brew install direnv
echo "$(direnv hook bash)" >> ~/.bash_profile
echo "$(direnv hook zsh)" >> ~/.zshrc
eval "$(direnv hook $SHELL)"

direnv allow <repository-directory>
```

### Running the build

To provision module infrastructure, run tests and then destroy that infrastructure,
execute:

```bash
./go
```

To provision the module prerequisites:

```bash
./go deployment:prerequisites:provision[<deployment_identifier>]
```

To provision the module contents:

```bash
./go deployment:harness:provision[<deployment_identifier>]
```

To destroy the module contents:

```bash
./go deployment:harness:destroy[<deployment_identifier>]
```

To destroy the module prerequisites:

```bash
./go deployment:prerequisites:destroy[<deployment_identifier>]
```


### Common Tasks

To generate an SSH key pair:

```
ssh-keygen -t rsa -b 4096 -C integration-test@example.com -N '' -f config/secrets/keys/bastion/ssh
```

Contributing
------------

Bug reports and pull requests are welcome on GitHub at https://github.com/tobyclemson/terraform-aws-bastion. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to 
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


License
-------

The library is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


