
let AwsR =
  { profile : Text
  , region : Text
  , version : Text
  } in
let NullR =
  { version : Text } in
let Null = \(x : NullR) -> <Aws : { aws : List AwsR } | Null = x > in
let Aws = \(x : AwsR) -> <Aws = { aws = [x] } | Null : NullR> in

{ provider =
  [ Aws { profile = "dev", region = "eu-west-2", version = "= 1.54.0" }
  , Null { version = "= 1.0" }
  ]
  , resource = "TODO"
}
