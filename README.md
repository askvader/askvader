- Website: https://www.terraform.io
- [![Gitter chat](https://badges.gitter.im/hashicorp-terraform/Lobby.png)](https://gitter.im/hashicorp-terraform/Lobby)
- Mailing list: [Google Groups](http://groups.google.com/group/terraform-tool)

<img alt="Noros" src="https://dl.dropboxusercontent.com/s/aig30sypi5avyul/noros_logo.png" width="600">

Noros is a cloud provisioning tool based on the [total](https://en.wikipedia.org/wiki/Total_functional_programming) configuration [Dhall](https://dhall-lang.org/) language. It lets you describe cloud infrastructure such as servers, storage, VPC, network setup, orchestration engines, batch jobs etc as *single expression*.


### Goals
- Capture the entire infrastucture as a *single, self-contained expression*
- Fully declarative: write an single expression and run `noros apply`
- Minimal and idempotent, encouraging fully automated and continous updates
- Use the same type-safe configuration language for everything
- Reproducible by default. If it deploys today it will deploy tomorrow (barring breaking API changes).

## Architecture

Noros uses Terraform, Packer and Nix under the hood. It can be seen as a wrapper around an opinionated subset of the capabilities of these tools.


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
