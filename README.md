- Website: https://www.terraform.io
- [![Gitter chat](https://badges.gitter.im/hashicorp-terraform/Lobby.png)](https://gitter.im/hashicorp-terraform/Lobby)
- Mailing list: [Google Groups](http://groups.google.com/group/terraform-tool)

<img alt="Noros" src="https://dl.dropboxusercontent.com/s/aig30sypi5avyul/noros_logo.png" width="600">

Noros is a cloud framework for the [Dhall](https://dhall-lang.org/) language. It allows the description of cloud infrastructure and configuration as *single expression*.

It uses Terraform, Packer and Nix under the hood and can be seen as a type-safe wrapper around these tools.

### Goals
- Capture the entire infrastucture (provisioning and configuration) as a *single, self-contained expression*
- Minimal and idempotent updates, encouraging fully automated and continous updates
- Single, type-safe configuration language

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
