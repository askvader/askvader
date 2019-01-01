
## Trying to deploy EC2 servers with Terraform+Nix

- Create default security group + IAM credentials in AWS console
- Copy AWS keys to `~/.aws/credentials` (*keep outside VC!*) under `dev` key
- Create Key pair 'admin' in AWS console save private key in `~/.aws/admin-key.pem`
  - Set permissions of the pem file to 600

- Allow TCP 22 incoming connections in default security group (necessary?)

- TODO make terraform treat change of provision artefacts as state change

- Deploy

    cd <THIS DIR>
    terraform init
    terraform apply
