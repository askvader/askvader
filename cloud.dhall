
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
		-- instance_type   = "m5d.2xlarge"
	, instanceType   = "t2.medium"
		-- instance_type = "i3.xlarge"
  }
in







--
-- AWS
--

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
TextP = {k:Text,v:Text}
in

let
-- TODO we could extend AwsAttribute with the Terraform built-in functions
AwsAttributeSet = List TextP
in
let
noAttrs = [] : List TextP
in


let
AwsInstanceR =
  -- Affects name of instance
  -- You must create a ServerConfig (Nix expression) of the same name
  { name : Text
  -- Server config expression, which must exists in top-level, or TF will complain
  , config : Text
  -- Attributes of other objects to pass to config (TODO pass from self)
  , configAttrs : AwsAttributeSet
  -- Generate a set of static files (subpaths of /var/static)
  , staticFiles : List { path : Text, content : Text }
  }
in

--
-- Defines AWS attribtues to query from Terraform resources or data sources.
--
-- TODO minimal example:
--  Boot N servers and dasy-chain so that each server knows about the previous one (if any)
--
-- Now:
-- Pass in untyped attribute set to each resource
-- Serverconfig will recieve this as [{name:Text,value:Text}]
--
-- Future:
-- For each new AwsResource (server) we define, pass in an attribute AND a function (a -> ServerConfig).
let
AwsAttribute =
	< S3BucketData :
		{ source : S3BucketR
		, attr :
			< Id : {}
			| Region : {}
			>
		}
  | AwsInstance :
    { source : AwsInstanceR
    , attr :
      < PrivateIp : {}
      >
    }
  >
in

let
AwsAttributes = constructors AwsAttribute
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
            instance_type		= "${standardAwsOptions.instanceType}"
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

let
awsInstanceShowingText = \(text : Text) ->
    AwsResources.AwsInstance
      { name = "foo"
      , config = "serverConfig" -- TODO actually use
      , configAttrs = noAttrs
      , staticFiles = [{path = "index.html", content =  text}]
      }
in
let
awsSingle = aws [awsInstanceShowingText "Nothing to see here!"]
in









-- Examples

let
exampleTwoServers =
  { main = aws
    [ AwsResources.AwsInstance
      { name = "foo"
      , config = "serverConfig" -- TODO actually use
      , configAttrs = noAttrs
      , staticFiles = [{path = "index.html", content = "This is foo, maam!"}]
      }
    , AwsResources.AwsInstance
      { name = "bar"
      , config = "serverConfig" -- TODO actually use
      , configAttrs = noAttrs
      , staticFiles = [{path = "index.html", content = "This is bar, sir!"}]
      }
    ]
  , server = staticSiteFromPath ""
  }
in

let
chainedServers =
  let
    s1 = awsInstanceShowingText "0"
  in
  let
    s2 = awsInstanceShowingText
        (getAttr (AwsAttributes.AwsInstance
                {source = s1, attr = PrivateIp {=}}))
  in
  { main = aws [s1, s2]
  , server = staticSiteFromPath ""
  }
in

-- A single-node Gitlab instance
-- Using a local PostgreSQL for persistence
--
-- Based on
--		https://nixos.org/nixos/manual/#module-services-gitlab
--
-- TODO this fails on the first deploy, only works on redeploy
let
testGitlab =
  let serverConfig =
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
          ''
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
          ''
        } -- TODO store elsewhere
      , extraConfig = { gitlab = { default_projects_features = { builds = False } } }
      }
    }
  }
  in
  { main = awsSingle, server = serverConfig }
in


-- TODO single NixOS machine with docker enabled
let
testDocker =
  let serverConfig =
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
  in
  { main = awsSingle, server = serverConfig }
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


-- A single node Consul cluster based on NixOS
-- TODO >1
--
-- TODO: More generally: passing data to managed nodes
let
testConsul =
  let serverConfig =
	{ networking =
		-- TODO on AWS, also requires 8500 to be in the Security Group
		-- TODO seems to work even with NixOS firewall disallowing 8500
		-- Is this firewall ignored on EC2?
		{ firewall = { enable = True
		, allowedTCPPorts = [ 80 ] } }
	, services =
		{ consul =
			{ enable = True
			, extraConfig =
				{ server = True
				, bootstrap_expect = 1
				, ui = True
				-- TODO exposes API without any ACL, dangerous!
  			, client_addr = "0.0.0.0"
				}
			}
		}
	}
  in
  { main = awsSingle, server = serverConfig }
in


{-
fun (X : sigT V) (Y : Type) (P : (forall Z : Type, V Z -> Y)) =>
    sigT_rect (fun _ : sigT V => Y)
              (fun (x : Type) (p : V x) =>
                 (fun X1 : V x -> Y => (fun X2 : Y => X2) (X1 p)) (P x)) X.

fun H : (forall Y : Type, (forall X : Type, V X -> Y) -> Y) =>
    H (sigT V) (fun (X : Type) (Y : V X) => existT V X Y)
---
Or something like
		[forall (b:Type) -> (forall (a:Type) -> {r:Res a,c:Cons a} -> b) -> b]

-}

-- Main

let
empty = { main = aws ([] : List AwsResource), server = {=} }
in

empty

-- TODO handle data sources and/or TF outputs
--
-- AS long as we're compiling to Text, we can't really process returned
-- data in any nice fashion (e.g. using typed Dhall). The initial reduction
-- step requires a normal form expression, so lambdas/continuations etc
-- are impossible.
--
-- TODO could this be solved with a dhall-to-terraform+JSON (or similar)
-- compiler, where intermediate evaluation is faked with 'external' resources?
--
-- Or we can fake it, having resources reference outputs in an untyped way.
-- E.g. 'here, use the IP of the resource named X if it exists' -> this we can
-- compile to normal TF interpolations. Or even take the Resources
--
{-
	Rethink current compilation strategy
	----
	Instead of creating effectively (Text, a, b, ...),
	use something like
		List { forall x y. this : Resource x, parent : Resource y, y -> NodeConf }

	---
	Won't work, we don't have existentials!

-}



-- TODO pin nixpkgs on the machines/AMI?

-- TODO support running more than one server config
--  E.g. by making user return a record of type
--    { main : TerraformConfig..., serverFoo : ServerConfig, serverBar... }


-- TODO configurable EC2 instance type/size

