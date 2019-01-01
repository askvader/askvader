
-- TODO pin prelude
let keyValue =
        https://prelude.dhall-lang.org/JSON/keyValue in
let concat =
        https://prelude.dhall-lang.org/List/concat in

-- let Dict = \(a : Type) -> List { mapKey : Text, mapValue : a } in
-- let JSON = <A : List JSON | O : Dict JSON | N : Natural | S : Text > in

-- More or less literal translation of terraform + nix file
-- TODO come up with something more high-level

{-
let AwsR =
  { profile : Text
  , region : Text
  , version : Text
  } in
let NullR =
  { version : Text } in
let Null = \(x : NullR) ->
  < Aws : { aws : List AwsR }
  | Null = { null = [x] }
  > in
let Aws = \(x : AwsR) ->
  < Aws = { aws = [x] }
  | Null : { null : List NullR }
  > in

let AwsInstanceR =
  { ami : Text
  , instance_type : Text
  , key_name : Text
  } in
let AwsInstance = \(name : Text) -> \(x : AwsInstanceR) ->
  < AwsInstance =
    { aws_instance =
    [ [{ mapKey = name, mapValue = [ x /\ { tags = [{Name=name}] } ] }] ]
    }
  | NullResource : {}
  >  in
let awsNix = \(name : Text) -> AwsInstance name in -- TODO
-}

{ terraformConfig =
  ''
  provider "aws" {
    region  = "eu-west-2"
    version = "= 1.54.0"
    // shared_credentials_file = "/Users/Hoglund/.aws/credentials"
    profile = "dev"
  }
  provider "null" {
    version = "= 1.0"
  }

  resource "aws_instance" "http-server" {
    // AMI from https://nixos.org/nixos/download.html
    ami             = "ami-0dada3805ce43c55e"
    instance_type   = "t2.micro"
    // instance_type   = "t2.medium"
    key_name        = "admin"

    tags {
      Name = "http-server"
    }
  }
  resource "null_resource" "http-server-prov" {
    triggers {
      build_number = "''${timestamp()}"
    }
    // For all provisioners
    connection {
      type = "ssh"
      user = "root"
      host = "''${element(aws_instance.http-server.*.public_ip, 0)}"
      private_key = "''${file("~/.aws/admin-key.pem")}"
    }

    // Copy NixOS config file
    provisioner "file" {
      source      = "http-server.nix"
      destination = "/etc/nixos/configuration.nix"
    }
    // TODO mkdir /var/www/blog
    provisioner "remote-exec" {
      inline = [
        "mkdir -p /var/www/blog"
      ]
    }
    // TODO copy index.html to above dir
    provisioner "file" {
      source      = "public/"
      destination = "/var/www/blog"
    }
    // TODO invoke nixos-rebuild switch
    provisioner "remote-exec" {
      inline = [
        "nixos-rebuild switch"
      ]
    }
    // TODO errors in above?
  }

  ''
, nixConfig = [ "TODO" ]
}
