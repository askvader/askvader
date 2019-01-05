
-- TODO pin prelude using
--    dhall resolve
let
concatMap = https://prelude.dhall-lang.org/Text/concatMap
in
let
generate = https://prelude.dhall-lang.org/List/generate
in



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
  provider "external" {
    version = "= 1.0.0"
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
	, instanceType = "t2.micro"
  -- instance_type   = "m5d.2xlarge"
	-- , instanceType   = "t2.medium"
		-- instance_type = "i3.xlarge"
    --
  -- In GB
  , rootBlockDeviceVolumeSize = 30 -- TODO too big?
  }
in







--
-- AWS
--
-- TODO flatten for easier construction
-- Could also provide extra records like:
--      AwsAttributes.Instance.PrivateIp x
--      AwsAttributes.Text.Instance.PrivateIp x
--      AwsAttributes.Bool.Instance.AssociatePublicIpAddress
--


--
-- In Terraform attributes provide 'delayed' values that become availible as
-- the resource graph is traversed and a resource is created.
-- We currently only support attributes of the following types:
--    Text
--    Natural
--    Boolean
--
-- Attributes can be used when defining resources, which implies a dependency.
-- Note recursive resource dependencies are *not* allowed, the resource graph
-- must be a DAG.
--
-- You can pass an arbirary number of attributes to a server or container
-- configuration expression. They types must correspond, e.g.
--
--    { config = \(x : Text) -> \(y : Optional Text) -> ...
--    , attributes = [someTextAttr, someOptionalAttr...]
--    ... }
--
let
AwsAttribute =
  < S3BucketId : Text -- { name : Text }
  | S3BucketRegion : Text -- { name : Text }
  | AwsInstancePrivateIp : Text -- { name : Text }
  >
in

--
-- Returns the Dhall type of the given AwsAttribute
--
let
typeOf = \(x : AwsAttribute) ->
  merge
  { S3BucketId = \(_:Text) -> "Text"
  , S3BucketRegion = \(_:Text) -> "Text"
  , AwsInstancePrivateIp = \(_:Text) -> "Text"
  }
  x : Text
in

let
AwsAttributes = constructors AwsAttribute
in


let
CannedACL =
	< Private : {}
	| PublicRead : {}
	| PublicReadWrite : {}
	>
	-- TODO ...
in
let
S3BucketR =
  { resourceName : Text
  , bucketName : Optional Text
  , acl : Optional CannedACL
	}
in


let
AwsInstanceR =
  -- Affects name of instance
  -- You must create a ServerConfig (Nix expression) of the same name
  { name : Text
  -- Config expression
  -- Must be Dhall function of type (A -> B) where A is the type corresponding
  -- to the value of configAttrs and B is a valid Nix expression.
  , config : Text
  -- Attributes to pass to the configuration
  , configAttrs : List AwsAttribute
  -- Generate a set of static files (subpaths of /var/static)
  , staticFiles : List { path : Text, content : Text }
  }
in


let
AwsResource =
  < AwsInstance : AwsInstanceR
  | S3Bucket : S3BucketR
  >
in
let
AwsResources = constructors AwsResource
in




-- Render an AWS resource in HCL as understood by terraform
-- Generates one or more 'resource' blocks
let
showAwsResource = \(res : AwsResource) ->
  -- Returns a Terraform splice for the given attribute or "{=}" for no attribute
  let
  getAttr = \(attr : AwsAttribute) ->
      merge
      { AwsInstancePrivateIp = \(name:Text) ->
          ''
          ''${aws_instance.${name}.private_ip}''
      , S3BucketId = \(name:Text) -> "TODO"
      , S3BucketRegion = \(name:Text) -> "TODO"
      }
      attr
      : Text
  in
  merge
    { S3Bucket = \(bucket : S3BucketR) ->
				"TODO"
		, AwsInstance = \(instance : AwsInstanceR) ->
      let
        name = instance.name
      in
      let
        staticFileBlock = List/fold {path:Text, content:Text} instance.staticFiles Text
          (\(x:{path:Text, content:Text}) -> \(rs:Text) ->
            ''
            provisioner "file" {
              destination = "/var/static/${x.path}"
              // TODO escape properly?
              content = "${x.content}"
            }
            ${rs}
            ''
          ) ""
      in
      let
        showAttrBlock = \(x : AwsAttribute) ->
          ", \"${getAttr x}\"\n"
      in
      let
        attrBlock = concatMap AwsAttribute showAttrBlock instance.configAttrs
      in
          -- TODO properly test chaining
          -- E.g. what comes out of TF for attribtues of differnt types
          -- Do we pass these to Dhall appropriately?
          ''
          data "external" "${name}-eval" {
            program =
              [ "./eval"
              // Pass code as first argument
              , <<EOF
              ${instance.config}
              EOF
              ${attrBlock}
              ]
            query =
              {
              }
          }
          resource "aws_instance" "${name}" {
            ami             = "${standardAwsOptions.ami}"
            instance_type		= "${standardAwsOptions.instanceType}"
            key_name        = "admin"

            tags {
              Name = "${name}"
            }

            root_block_device {
              volume_size = ${Natural/show standardAwsOptions.rootBlockDeviceVolumeSize}
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
              content = "''${data.external.${name}-eval.result.nix}"
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
                "cat /etc/nixos/configuration.nix",
                "nixos-rebuild switch"
              ]
            }
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
    (concatMap AwsResource showAwsResource resources)
in






--
-- High-level resources
--


let
awsInstanceShowingText = \(name : Text) -> \(text : Text) ->
      { name = name
      , config =
      ''
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
          }
        in
        staticSiteFromPath ""
      ''
      , configAttrs = [] : List AwsAttribute
      , staticFiles = [{path = "index.html", content =  text}]
      }
in



let
awsSingleWith = \(config : Text) -> aws [
  AwsResources.AwsInstance
      { name = "single"
      , config = config
      , configAttrs = [] : List AwsAttribute
      , staticFiles = [{path = "index.html", content = "none"}]
      }
]
in







-- Examples

-- A single-node Gitlab instance
-- Using a local PostgreSQL for persistence
--
-- Based on
--		https://nixos.org/nixos/manual/#module-services-gitlab
--
-- TODO this fails on the first deploy, only works on redeploy
-- TF timeouts?
let
testGitlab =
  let serverConfig =
  ''
{ networking =
	{ firewall = { enable = True, allowedTCPPorts = [ 80 ] } }
  , services =
    { nginx =
      {
        enable = True
      , recommendedGzipSettings = True
      , recommendedOptimisation = True
      , recommendedProxySettings = True
      , recommendedTlsSettings = True
      , virtualHosts =
        { gitLab =
          {
          -- , enableACME = True
          -- , forceSSL = True
            locations = { dhallEscapeSlash = { proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket" }}
          }
        }
      }
    , gitlab =
      {
        enable = True
      , databasePassword = "187827837"
      , initialRootPassword = "982938918"
      , https = False
      , host = "localhost"
      , port = 80 -- TODO use SSL
      , user = "git"
      , group = "git"
      , secrets =
        { secret = "devzJ0Tz0POiDBlrpWmcLltyiAdS8TtgT9YNBOoUcDsfppiY3IXZjMVtKgXrFImIennFGOpPN8IkP8ATXpRgDD5rxVnKuTTwYQaci2NtaV1XxOQGjdIE50VGsR3"
        , otp = "devzJ0Tz0POiDBlrpWmcLltyiAdS8TtgT9YNBOoUcDsfppiY3IXZjMVtKgXrFImIennFGOpPN8IkP8ATXpRgDD5rxVnKuTTwYQaci2NtaV1XxOQGjdIE50VGsR3"
        , db = "uPgq1gtwwHiatiuE0YHqbGa5lEIXH7fMsvuTNgdzJi8P0Dg12gibTzBQbq5LT7PNzcc3BP9P1snHVnduqtGF43PgrQtU7XL93ts6gqe9CBNhjtaqUwutQUDkygP5NrV6"
        , jws =
          '''
					-----BEGIN RSA PRIVATE KEY-----
					MIIEpAIBAAKCAQEArrtx4oHKwXoqUbMNqnHgAklnnuDon3XG5LJB35yPsXKv/8GK
					ke92wkI+s1Xkvsp8tg9BIY/7c6YK4SR07EWL+dB5qwctsWR2Q8z+/BKmTx9D99pm
					hnsjuNIXTF7BXrx3RX6BxZpH5Vzzh9nCwWKT/JCFqtwH7afNGGL7aMf+hdaiUg/Q
					SD05yRObioiO4iXDolsJOhrnbZvlzVHl1ZYxFJv0H6/Snc0BBA9Fl/3uj6ANpbjP
					eXF1SnJCqT87bj46r5NdVauzaRxAsIfqHroHK4UZ98X5LjGQFGvSqTvyjPBS4I1i
					s7VJU28ObuutHxIxSlH0ibn4HZqWmKWlTS652wIDAQABAoIBAGtPcUTTw2sJlR3x
					4k2wfAvLexkHNbZhBdKEa5JiO5mWPuLKwUiZEY2CU7Gd6csG3oqNWcm7/IjtC7dz
					xV8p4yp8T4yq7vQIJ93B80NqTLtBD2QTvG2RCMJEPMzJUObWxkVmyVpLQyZo7KOd
					KE/OM+aj94OUeEYLjRkSCScz1Gvq/qFG/nAy7KPCmN9JDHuhX26WHo2Rr1OnPNT/
					7diph0bB9F3b8gjjNTqXDrpdAqVOgR/PsjEBz6DMY+bdyMIn87q2yfmMexxRofN6
					LulpzSaa6Yup8N8H6PzVO6KAkQuf1aQRj0sMwGk1IZEnj6I0KbuHIZkw21Nc6sf2
					ESFySDECgYEA1PnCNn5tmLnwe62Ttmrzl20zIS3Me1gUVJ1NTfr6+ai0I9iMYU21
					5czuAjJPm9JKQF2vY8UAaCj2ZoObtHa/anb3xsCd8NXoM3iJq5JDoXI1ldz3Y+ad
					U/bZUg1DLRvAniTuXmw9iOTwTwPxlDIGq5k+wG2Xmi1lk7zH8ezr9BMCgYEA0gfk
					EhgcmPH8Z5cU3YYwOdt6HSJOM0OyN4k/5gnkv+HYVoJTj02gkrJmLr+mi1ugKj46
					7huYO9TVnrKP21tmbaSv1dp5hS3letVRIxSloEtVGXmmdvJvBRzDWos+G+KcvADi
					fFCz6w8v9NmO40CB7y/3SxTmSiSxDQeoi9LhDBkCgYEAsPgMWm25sfOnkY2NNUIv
					wT8bAlHlHQT2d8zx5H9NttBpR3P0ShJhuF8N0sNthSQ7ULrIN5YGHYcUH+DyLAWU
					TuomP3/kfa+xL7vUYb269tdJEYs4AkoppxBySoz8qenqpz422D0G8M6TpIS5Y5Qi
					GMrQ6uLl21YnlpiCaFOfSQMCgYEAmZxj1kgEQmhZrnn1LL/D7czz1vMMNrpAUhXz
					wg9iWmSXkU3oR1sDIceQrIhHCo2M6thwyU0tXjUft93pEQocM/zLDaGoVxtmRxxV
					J08mg8IVD3jFoyFUyWxsBIDqgAKRl38eJsXvkO+ep3mm49Z+Ma3nM+apN3j2dQ0w
					3HLzXaECgYBFLMEAboVFwi5+MZjGvqtpg2PVTisfuJy2eYnPwHs+AXUgi/xRNFjI
					YHEa7UBPb5TEPSzWImQpETi2P5ywcUYL1EbN/nqPWmjFnat8wVmJtV4sUpJhubF4
					Vqm9LxIWc1uQ1q1HDCejRIxIN3aSH+wgRS3Kcj8kCTIoXd1aERb04g==
					-----END RSA PRIVATE KEY-----
          '''
        } -- TODO store secrets elsewhere
      , extraConfig = { gitlab = { default_projects_features = { builds = False } } }
      }
    }
  }
  ''
  in
  { main = awsSingleWith serverConfig }
in


-- A single NixOS machine with docker enabled
let
testDocker =
  let serverConfig =
  ''
	{ virtualisation =
		{ docker =
			{ enable = True }
		}
	, users =
		{ users	=
			{ root =
				{ extraGroups = ["docker"] }
			}
		}
	}
  ''
  in
  { main = awsSingleWith serverConfig }
in


-- TODO get TF to boot EKS cluster and run standard containers in there (e.g. consul cluster)

-- TODO NixOS machine with docker + standard consul image
-- E.g. as above, then run:
-- 		docker pull consul
-- 		docker run -t -i consul agent -bootstrap-expect=1 -server


-- TODO build custom Docker images using NixOS (preferably driven by expressions, similar to our NixOS provisioning)
--   See: https://nixos.wiki/wiki/Docker

-- TODO Consul cluster based on Docker+Kubernetes?
-- TODO more generally: config/launch containers in EKS, or functions in Lambda as an alternative to NixOS/EC2


-- A Consul cluster of N servers and 0 clients
-- TODO clients!
let
testConsul =
  let nMinus1 = 4
  in
  let config =
  ''
  \(peer : Text) ->
	{ networking =
		-- TODO on AWS, also requires 8500 to be in the Security Group
		-- TODO seems to work even with NixOS firewall disallowing 8500
		-- Is this firewall ignored on EC2?
		{ firewall = { enable = False
		, allowedTCPPorts = [ 80, 8500 ] } }
	, services =
		{ consul =
			{ enable = True
			, extraConfig =
				{ server = True
				, bootstrap_expect = ${Natural/show (nMinus1 + 1)}
				, ui = True
				-- TODO exposes API without any ACL, dangerous!
  			, bind_addr = "{{GetPrivateIP}}"
        , client_addr = "0.0.0.0"
        , retry_join = [peer]
        }
			}
		}
	}
  ''
  in
  { main =
    aws (
    [ AwsResources.AwsInstance
      { name = "c"
      -- TODO use a config that exludes the peer field for the first node
      , config = "(" ++ config ++ ")\"127.0.0.1\""
      , configAttrs = [] : List AwsAttribute
      , staticFiles = [{path = "index.html", content = "none"}]
      }
    ]
    #
    generate nMinus1 AwsResource (\(n : Natural) ->
      AwsResources.AwsInstance
        { name = "c" ++ Natural/show n
        , config = config
        , configAttrs = [AwsAttributes.AwsInstancePrivateIp "c"]
        , staticFiles = [{path = "index.html", content = "none"}]
        })
    )
  }
in


let
empty = { main = aws ([] : List AwsResource) }
in

testGitlab



-- TODO pin nixpkgs on the machines/AMI?
-- See:
--    http://www.haskellforall.com/2018/08/nixos-in-production.html

-- TODO configurable EC2 instance type/size

