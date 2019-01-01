
{ provider =
  [ < Aws = { foo = 1 } | Null : { bar : Natural } >
  , < Aws : { foo : Natural } | Null = { bar = 1 } >
  ]
, resource = "TODO"
}
