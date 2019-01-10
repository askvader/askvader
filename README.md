[![GitHub release](https://img.shields.io/github/release/haskell/ghcup.svg)](https://github.com/haskell/ghcup/releases)
[![Build Status](https://travis-ci.org/haskell/ghcup.svg?branch=master)](https://travis-ci.org/haskell/ghcup)
[![license](https://img.shields.io/github/license/haskell/ghcup.svg)](COPYING.md)

<img alt="Noros" src="https://dl.dropboxusercontent.com/s/xrw0wxu7imjsvgt/askvader_sm.png" width="190" align="left">

## Askvader

*WARNING: Askvader is pre-alpha*.

Askvader is a typed, purely functional language that compiles to distributed cloud applications. It can be thought of as a provisioner for cloud environments like Kubernetes or AWS, or as a programming language that uses these systems as its runtime environment. The core design goals are:

- *Immutablity*: All your infrastructure should be as a single expression
- *Reproduciblity*: The meaning of an expression does not depend on any external state
- *Safety*: The type checker should catch as many errors as possible before deployment

[Examples](#examples) · [FAQ](#faq) · [Tracker](https://github.com/askvader/askvader/issues)

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
- Web stack with DBs web app
```elm
let server = ./core/server/nodejs
in let db = ./core/database
in let core = ./core
in let dbRootPassword = core.secrets.randomAlpha 20 "dbroot"
in server
  { handlerFunction = ... dbRootPassword
  , database =
    { type = db.Types.PostgreSQL
    , production = False
    , maxStorage = core.units.gb 20
    , name = "foobar"
    , rootUser = "root"
    , rootPassword = dbRootPassword
    }
  }
```
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
- *Where does the name come from?* Åskväder is Swedish for *thunderstorm*.
- *What environments does Askvader support?*. The only first-class backends are AWS and Kubernetes (including EKS and minikube).
<!--
- *How does Askvader relate to Nix/NixOS?* Askvader can provision NixOS machines with configurations written in the Nix language or the Askvader language.
- *How does Askvader relate to Terraform?* Askvader includes libraries for generating HCL understood by Terraform. This is used as a backend for the AWS/Kubernetes functionality.
- *How does Askvader relate to Docker/Packer?* Askvader can generate containers using Docker or Packer as a backend.
- *How does Askvader relate to Kubernetes?* Askvader can provision Kubernetes clusters.
- *How does Askvader relate to Helm?* Askvader does not include first-class support for Helm, and is best thought of as an alternative to it.
- *How does Askvader relate to Ansible/Puppet/Salt etc?* Askvader does not include first-class support for these tools, and is best thought of as an alternative to them.
-->
- *What is the Askvader language based on?* It is based on [Dhall](). Specifically Askvader is a standard-compliant Dhall implementation with extra libraries and tooling.

- *Where does Askvader store state?* Askvader manages state as part of the backend. E.g. for AWS, the state is stored in S3. The DBs/buckets are prefixed with `av.state` by default. Note: AV writes the state atomically as the last step of deploy. I this fails deployment is considered unsuccessful.

---
### CLI
```
av deploy           Deploy current expression
av undeploy         Undo all current deployment (equivalent to deploying an empty configuration)
av version          Print version

av resolve
av type             Infer/typecheck
av normalize
av repl
av hash
av format

av eval             (Internal command)
```

---
### Core design "laws"
- The (hash of the) single (resolved) expression should determine observable behaviour (e.g. no mutable dependencies, including local file system)

- Any state backend maintains (hashes of?) previously resolved expression + state info for that deployment (including a bool: scuccess or not)
- TODO atomicity/state
    av deploy E1 to B <- success
    av deploy E2 to B <- fail
      what is the state of B?
        in TF it is undefined
        in a single machine Nix it is typically atomic
  ACID by default would be *great*
  Failed deployments logged in state backend, but *ignored* (underlying infra does not shift)
    E.g. no need for rollbacks (unless for other reasons)
    E.g. use blue/green in all backends by default)
    NOTE carnary can be achieved on top of this

- Deploying E twice in a sequence
- `av deploy` should either fail or return a valid config - *ideally* catching failues before making any changes
- `av undeploy` should undo everything that has ever been deployed by AV to this backend instance (AWS account, Kubernetes cluster)

--

### Getting started (AWS)

*WARNING: This may incur charges. Keep an eye on the billing dashboard in your cloud provider.*.

- Create default security group + IAM credentials in AWS console
- Copy AWS keys to `~/.aws/credentials` (*keep outside VC!*) under `dev` key
- Create Key pair 'admin' in AWS console save private key in `~/.aws/admin.pem`
  - Set permissions of the pem file to 600
  - Allow TCP 22 incoming connections in default security group

