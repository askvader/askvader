- Website: https://www.terraform.io
- [![Gitter chat](https://badges.gitter.im/hashicorp-terraform/Lobby.png)](https://gitter.im/hashicorp-terraform/Lobby)
- Mailing list: [Google Groups](http://groups.google.com/group/terraform-tool)

<img alt="Noros" src="https://dl.dropboxusercontent.com/s/aig30sypi5avyul/noros_logo.png" width="600">

Noros is an cloud framework based on the [Dhall](https://dhall-lang.org/) language. It is an opinionated wrapper around Terraform and Nix, with the following goals:

- The infrastructure (both provisioning and configuration) should be captured in code
- A cloud infrastucture should be *single expression*
- Deploying should be idempotent, encouraging continous redeploys of the infrastructure state
- Errors should be catched by the type checker before deploying

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
