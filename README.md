[![GitHub release](https://img.shields.io/github/release/askvader/askvader.svg)](https://github.com/askvader/askvader/releases)
[![Build Status](https://travis-ci.org/askvader/askvader.svg?branch=master)](https://travis-ci.org/askvader/askvader)
[![license](https://img.shields.io/github/license/askvader/askvader.svg)](COPYING.md)

<img alt="Noros" src="https://dl.dropboxusercontent.com/s/xrw0wxu7imjsvgt/askvader_sm.png" width="190" align="left">

## Askvader

Askvader is an experimental compiler for [Dhall]() which generates distributed systems running in cloud environments such as Kubernetes or AWS. The implementation currently uses [Terraform](), [Packer]() and [NixOS]() to create and manage the underlying resources, which means Askvader is also a high-level interface to some of the most powerful cloud provisioning tools.

[Examples](#examples) · [Tracker](https://github.com/askvader/askvader/issues)

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
    How to achieve blue/green in
      k8s
        As per https://github.com/ContainerSolutions/k8s-deployment-strategies/blob/master/blue-green/multiple-services/ingress-v2.yaml
        Include version/hash in all pods/services
        Switch incoming API server atomically
          TODO atomically update state key at the same time?
      EC2
        Use El IP? TODO how to atomically switch this along with state key?

- Deploying E twice in a sequence
- `av deploy` should either fail or return a valid config - *ideally* catching failues before making any changes
- `av undeploy` should undo everything that has ever been deployed by AV to this backend instance (AWS account, Kubernetes cluster)

- TODO simple model on basic concerns (minimizing impl works!)
  - Atomic updates (blue/green)
  - Handling of failed updates (returning non-0, if using blue/green: no change to observable state, error messages)
  - Caching (e.g. reuse work, make manual rollbacks cheap)
  - No boot/update distinction (assumption of state backend exists) -> also put AV version here.
  - Logging/monitoring by default?
  - Secrets

- NO depencency on RT information, all eval happens up-front (but eval may return functions, which are turned into applications later)
  - In other words *type* errors should not be possible after deployment succeeds

--

### Getting started (AWS)

*WARNING: This may incur charges. Keep an eye on the billing dashboard in your cloud provider.*.

- Create default security group + IAM credentials in AWS console
- Copy AWS keys to `~/.aws/credentials` (*keep outside VC!*) under `dev` key
- Create Key pair 'admin' in AWS console save private key in `~/.aws/admin.pem`
  - Set permissions of the pem file to 600
  - Allow TCP 22 incoming connections in default security group

