
-- TODO pin prelude

-- let Dict = \(a : Type) -> List { mapKey : Text, mapValue : a } in
-- let JSON = <A : List JSON | O : Dict JSON | N : Natural | S : Text > in






-- Terraform providers used by the code we generate
-- Hardcoded for now
let
standardProviders =
  ''
  provider "aws" {
    region  = "eu-west-2"
    version = "= 1.54.0"
    profile = "dev"
  }
  provider "null" {
    version = "= 1.0"
  }
  ''
in

-- Standard AWS options
-- Hardcoded for now
let
standardAwsOptions =
  -- AMI from https://nixos.org/nixos/download.html
  -- Nixos 18.09
  { ami = "ami-0dada3805ce43c55e"
  , keyName = "admin"
  }
in







--
-- AWS
--

let
AwsInstanceR =
  -- Affects name of instance
  -- You must create a ServerConfig (Nix expression) of the same name
  { name : Text
  -- Generate a set of static files (subpaths of /var/static)
  , staticFiles : List { path : Text, content : Text }
  }
in
let
AwsResource =
  < AwsInstance : AwsInstanceR
  >
in
let
  AwsResourceC = constructors AwsResource
in


-- Render an AWS resource in HCL as understood by terraform
-- Generates one or more 'resource' blocks
let
showAwsResource = \(res : AwsResource) ->
  merge
    { AwsInstance = \(instance : AwsInstanceR) ->
      let
        name = instance.name
      in
      let
        staticFileBlock = List/fold {path:Text, content:Text} instance.staticFiles Text
          (\(x:{path:Text, content:Text}) -> \(rs:Text) ->
            ''
            provisioner "file" {
              destination = "/var/static/${x.path}"
              // TODO escape string
              content = "${x.content}"
            }
            ${rs}
            ''
          ) ""
      in
          ''
          resource "aws_instance" "${name}" {
            ami             = "${standardAwsOptions.ami}"
            // instance_type   = "m5d.2xlarge"
            instance_type   = "t2.medium"
            // instance_type = "i3.xlarge"
            key_name        = "admin"

            tags {
              Name = "${name}"
            }

            root_block_device {
              volume_size = 30 // TODO big!
            }
          }
          resource "null_resource" "${name}-prov" {
            triggers {
              build_number = "''${timestamp()}"
            }
            connection {
              type = "ssh"
              user = "root"
              host = "''${element(aws_instance.${name}.*.public_ip, 0)}"
              private_key = "''${file("~/.aws/${standardAwsOptions.keyName}.pem")}"
            }
            provisioner "file" {
              // TODO this name is hardcoded in ./deploy
              source      = "cloud.nix"
              destination = "/etc/nixos/configuration.nix"
            }
            provisioner "remote-exec" {
              inline = [
                "mkdir -p /var/static"
              ]
            }
            ${staticFileBlock}
            provisioner "remote-exec" {
              inline = [
                "nixos-rebuild switch"
              ]
            }
            // TODO errors in above?
          }

          ''
    }
  res
  : Text
in

-- Transform a list of AWS resources into a Terraform config
let
  aws = \(resources : List AwsResource) ->
    standardProviders
    ++
    (
    let concatMap = https://prelude.dhall-lang.org/Text/concatMap in
    (concatMap AwsResource showAwsResource resources)
    )
in






--
-- High-level resources
--

let
StaticHTTPServer =
  { networking :
      { firewall : { enable : Bool, allowedTCPPorts : List Natural } }
  , services :
      { nginx : { enable : Bool, virtualHosts : { site : { root : Text } } } }
  }
in

-- Serve a static HTTP site on port 80 from the given path
-- All paths are relative to /var/static, pass "" to serve that entire directory
-- Hint: combine with staticFiles to generate content
let
staticSiteFromPath = \(path : Text) ->
  { networking =
      { firewall = { enable = True, allowedTCPPorts = [ 80 ] } }
  , services =
      { nginx =
          { enable = True, virtualHosts = { site = { root = "/var/static" ++ path } } }
      }
  } : StaticHTTPServer
in









-- Examples
let
awsSingle
  = aws
    [ AwsResourceC.AwsInstance
      { name = "foo"
      , staticFiles = [{path = "index.html", content = "Nothing to see here!"}]
      }
    ]
in

let
exampleTwoServers =
  { main = aws
    [ AwsResourceC.AwsInstance
      { name = "foo"
      , staticFiles = [{path = "index.html", content = "This is foo, maam!"}]
      }
    , AwsResourceC.AwsInstance
      { name = "bar"
      , staticFiles = [{path = "index.html", content = "This is bar, sir!"}]
      }
    ]
    , server = staticSiteFromPath ""
  }
in


let
-- Gitlab example
--
-- See https://nixos.org/nixos/manual/#module-services-gitlab
-- TODO root volume size issue for NixOS?
testGitlab =
  let serverConfig =
  { services = { gitlab =
  {
    enable = True
  , databasePassword = "redacted"
  , https = True
  , host = "yolovo.test.bpletza.de"
  , port = 443
  , user = "git"
  , group = "git"
  , secrets =
    { secret = "haha"
    , otp = ""
    , db = ""
    , jws = ""
    } -- TODO store elsewhere
  , extraConfig = { gitlab = { default_projects_features = { builds = False } } }
  }
  }
  }
  in
  { main = awsSingle, server = serverConfig }
in






-- Main

testGitlab

-- TODO pin nixpkgs on the machines/AMI?

-- TODO support running more than one server config
--  E.g. by making user return a record of type
--    { main : TerraformConfig..., serverFoo : ServerConfig, serverBar... }


-- TODO configurable EC2 instance type/size

-- TODO learn about AWSs EFS vs EBS
