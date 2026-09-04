module DigitalOcean.Resource.Vpc
  ( Args
  , Required
  , Vpc
  , VpcResource
  , args
  , create
  , description
  , id
  , ipRange
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data VpcResource

type Required =
  { name :: Input String
  , region :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  ])

description :: Input String -> Args -> Args
description value (Args values) = Args (Object.insert "description" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

ipRange :: Input String -> Args -> Args
ipRange value (Args values) = Args (Object.insert "ip_range" (inputJson value) values)

timeouts :: Input ({ delete :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

type Vpc =
  { resource :: Resource VpcResource
  , createdAt :: Expr String
  , default :: Expr Boolean
  , description :: Expr String
  , id :: Expr String
  , ipRange :: Expr String
  , name :: Expr String
  , region :: Expr String
  , urn :: Expr String
  }

create :: String -> Args -> Infra Vpc
create logicalName (Args values) = do
  handle <- addResource "digitalocean_vpc" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , default: resourceAttr handle [ "default" ]
    , description: resourceAttr handle [ "description" ]
    , id: resourceAttr handle [ "id" ]
    , ipRange: resourceAttr handle [ "ip_range" ]
    , name: resourceAttr handle [ "name" ]
    , region: resourceAttr handle [ "region" ]
    , urn: resourceAttr handle [ "urn" ]
    }
