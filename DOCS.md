## Use

```shell
askvader deploy my-expression.av
```

## Credentials & Security

*Warning*: Your cloud provider may charge you for resources you request using Askvader. 

Askvader for now only runs in `development` mode. In this mode the creator has full SSH access to all instances/VMs etc. using their standard public key.

Askvader looks for AWS and SSH credentials in the standard locations:

```
cat ~/.ssh/id_rsa.pub
ssh-rsa ...

cat ~/.aws/credentials
[default]                                                                                                                                                                                                                                       
aws_access_key_id = ...                                                                                                                                                                                                    
aws_secret_access_key = ...  
```
