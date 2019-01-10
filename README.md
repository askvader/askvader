[![GitHub release](https://img.shields.io/github/release/haskell/ghcup.svg)](https://github.com/haskell/ghcup/releases)
[![Build Status](https://travis-ci.org/haskell/ghcup.svg?branch=master)](https://travis-ci.org/haskell/ghcup)
[![license](https://img.shields.io/github/license/haskell/ghcup.svg)](COPYING)

<img alt="Noros" src="https://dl.dropboxusercontent.com/s/xrw0wxu7imjsvgt/askvader_sm.png" width="190" align="left">

## Askvader

*WARNING: Askvader is pre-alpha*.

Askvader is a typed, purely functional language that compiles to distributed systems, running on Kubernetes or standard cloud providers such as AWS. Askvader can be thought of a powerful provisioning tool, or as a programming language in its own right. The core design goals are:

- *Immutablity*: All your infrastructure should be as a single expression
- *Reproduciblity*: The meaning of an expression does not depend on any external state
- *Safety*: The type checker should catch as many errors as possible before deployment

## Examples

### Generic
- Static web servers

```elm
let staticServer = ./core/server/static
in staticServer 
  { indexFile = "Welcome! Please try <a href=\"b.html\">this page</a>."
  , otherFiles = [{ name = "b.html", content = "This is another file!" }] 
  }
```
- Web stack with DBs
- Load balancers
- Consul cluster
- Gitlab + Build workers
### AWS
- Instances
- Volumes
- Spot/reserved
- IAM users/groups
```elm
let aws = ./providers/aws
let alice = aws.user { name = "alice" }
in let bob = aws.user { name = "bob" }
in
  { main = aws.resources
    [ alice
    , bob
    , aws.group
      { name = "people"
      , members = [alice, bob]
      }
     ]
  } 
```
- VPC
- Custom AMIs
### Kubernetes
- Custom containers

## FAQ
- *What is the status of Askvader?* Experimental. Do not use in production yet.
- *What environments does Askvader support?*. The only first-class backends are AWS and Kubernetes (including EKS and minikube).
- *How does Askvader relate to Nix/NixOS?* Askvader can provision NixOS machines with configurations written in the Nix language or the Askvader language.
- *How does Askvader relate to Terraform?* Askvader includes libraries for generating HCL understood by Terraform. This is used as a backend for the AWS/Kubernetes functionality.
- *How does Askvader relate to Docker/Packer?* Askvader can generate containers using Docker or Packer as a backend. 
- *How does Askvader relate to Kubernetes?* Askvader can provision Kubernetes clusters.
- *How does Askvader relate to Helm?* Askvader does not include first-class support for Helm, and is best thought of as an alternative to it.
- *How does Askvader relate to Ansible/Puppet/Salt etc?* Askvader does not include first-class support for these tools, and is best thought of as an alternative to them.
- *What is the Askvader language based on?* It is based on [Dhall]().
- *What is the difference between Askvader and Dhall?* None. Askvader is a standard-compliant Dhall implementation.
- *Where does the name come from?* Åskväder is Swedish for *thunderstorm*.

---
### For devs - core design
- `askvader deploy` should either fail or return a valid config - ideally catching failues before making any changes
- `askvader undeploy` should undo entirety of last apply (similar to applying an empty config)
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
