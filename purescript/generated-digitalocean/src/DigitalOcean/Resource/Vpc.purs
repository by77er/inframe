module DigitalOcean.Resource.Vpc
  ( Args
  , Required
  , Vpc
  , VpcResource
  , args
  , create
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsDelete
  , description
  , id
  , ipRange
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data VpcResource

newtype Timeouts = Timeouts InputObject

type TimeoutsRequired =
  {
  }

timeoutsArgs :: TimeoutsRequired -> Timeouts
timeoutsArgs _ = Timeouts (inputObject
  [
  ])

timeoutsDelete :: Input String -> Timeouts -> Timeouts
timeoutsDelete value (Timeouts values) = Timeouts (insertInputField "delete" (inputJson value) values)

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  { name :: Input String
  , region :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  ])

description :: Input String -> Args -> Args
description value (Args values) = Args (insertInputField "description" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

ipRange :: Input String -> Args -> Args
ipRange value (Args values) = Args (insertInputField "ip_range" (inputJson value) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

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
