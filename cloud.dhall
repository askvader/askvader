
-- TODO pin prelude
let keyValue =
        https://prelude.dhall-lang.org/JSON/keyValue in
let concat =
        https://prelude.dhall-lang.org/List/concat in



-- More or less literal translation of terraform + nix file
-- TODO come up with something more high-level

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

{ terraformConfig = { provider =
    [ Aws { profile = "dev", region = "eu-west-2", version = "= 1.54.0" }
    , Null { version = "= 1.0" }
    ]
    , resource =
    [ AwsInstance "http-server"
      { ami = "ami-0dada3805ce43c55e"
      , instance_type = "t2.micro"
      , key_name = "admin"
      }
    ]
  }
, nixConfig = [ "TODO" ]
}
