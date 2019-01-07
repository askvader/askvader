- [![Gitter chat](https://badges.gitter.im/hashicorp-terraform/Lobby.png)](https://gitter.im/hashicorp-terraform/Lobby)

<img alt="Noros" src="https://dl.dropboxusercontent.com/s/aig30sypi5avyul/noros_logo.png" width="600">

Noros is a library of cloud infrastructure written in Dhall.

It can be used describe Nix configurations and Docker containers, and supports deployment on AWS EC2, Kubernetes and NixOS. Terraform is used to bootstrap the infrastructure, though this is mostly hidden from the user.


### Goals
- Immutable: Describe your infrastructure as a single, immutable expression
- Reproducible: Expressions are designed to work forever
- Powerful: Use the full power of Dhall to generate arbitrarily complex setup
- Safe: The type checker catches most errors before deployment

### For devs - core design
- `noros apply` should either fail or return a valid config - ideally catching failues before making any changes
- `noros destroy` should undo entirety of last apply (similar to applying an empty config)
- The (hash of the) single (resolved) expression should determine observable behaviour (e.g. no mutable dependencies, including local file system)

--

### Getting started

- Create default security group + IAM credentials in AWS console
- Copy AWS keys to `~/.aws/credentials` (*keep outside VC!*) under `dev` key
- Create Key pair 'admin' in AWS console save private key in `~/.aws/admin.pem`
  - Set permissions of the pem file to 600
  - Allow TCP 22 incoming connections in default security group

### Deploy

    ./deploy

### Undeploy

    terraform destroy
