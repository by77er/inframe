module DigitalOcean.Resource.Record
  ( Args
  , Required
  , RecordHandle
  , RecordResource
  , args
  , create
  , flags
  , id
  , port
  , priority
  , tag
  , ttl
  , weight
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data RecordResource

type Required =
  { domain :: Input String
  , name :: Input String
  , type_ :: Input String
  , value :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "domain" (inputJson required.domain)
  , Tuple "name" (inputJson required.name)
  , Tuple "type" (inputJson required.type_)
  , Tuple "value" (inputJson required.value)
  ])

flags :: Input Number -> Args -> Args
flags value (Args values) = Args (insertInputField "flags" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

port :: Input Number -> Args -> Args
port value (Args values) = Args (insertInputField "port" (inputJson value) values)

priority :: Input Number -> Args -> Args
priority value (Args values) = Args (insertInputField "priority" (inputJson value) values)

tag :: Input String -> Args -> Args
tag value (Args values) = Args (insertInputField "tag" (inputJson value) values)

ttl :: Input Number -> Args -> Args
ttl value (Args values) = Args (insertInputField "ttl" (inputJson value) values)

weight :: Input Number -> Args -> Args
weight value (Args values) = Args (insertInputField "weight" (inputJson value) values)

type RecordHandle =
  { resource :: Resource RecordResource
  , domain :: Expr String
  , flags :: Expr Number
  , fqdn :: Expr String
  , id :: Expr String
  , name :: Expr String
  , port :: Expr Number
  , priority :: Expr Number
  , tag :: Expr String
  , ttl :: Expr Number
  , type_ :: Expr String
  , value :: Expr String
  , weight :: Expr Number
  }

create :: String -> Args -> Infra RecordHandle
create logicalName (Args values) = do
  handle <- addResource "digitalocean_record" logicalName values
  pure
    { resource: handle
    , domain: resourceAttr handle [ "domain" ]
    , flags: resourceAttr handle [ "flags" ]
    , fqdn: resourceAttr handle [ "fqdn" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , port: resourceAttr handle [ "port" ]
    , priority: resourceAttr handle [ "priority" ]
    , tag: resourceAttr handle [ "tag" ]
    , ttl: resourceAttr handle [ "ttl" ]
    , type_: resourceAttr handle [ "type" ]
    , value: resourceAttr handle [ "value" ]
    , weight: resourceAttr handle [ "weight" ]
    }
