[![GitHub release](https://img.shields.io/github/release/haskell/ghcup.svg)](https://github.com/haskell/ghcup/releases)
[![Build Status](https://travis-ci.org/haskell/ghcup.svg?branch=master)](https://travis-ci.org/haskell/ghcup)
[![license](https://img.shields.io/github/license/haskell/ghcup.svg)](COPYING)

<img alt="Noros" src="https://dl.dropboxusercontent.com/s/xrw0wxu7imjsvgt/askvader_sm.png" width="150" align="left">

## Askvader

Askvader is a typed, purely functional language that compiles to cloud infrastructure.

- *Immutable*: All your infrastructure should be as a single expression
- *Reproducible*: The meaning of an expression does not depend on any external state
- *Safe*: The type checker should catch as many errors as possible before deployment






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
