module DigitalOcean.Resource.ByoipPrefix
  ( Args
  , Required
  , ByoipPrefix
  , ByoipPrefixResource
  , args
  , create
  , advertised
  , id
  , signature
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data ByoipPrefixResource

type Required =
  { prefix :: Input String
  , region :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "prefix" (inputJson required.prefix)
  , Tuple "region" (inputJson required.region)
  ])

advertised :: Input Boolean -> Args -> Args
advertised value (Args values) = Args (insertInputField "advertised" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

signature :: Input String -> Args -> Args
signature value (Args values) = Args (insertInputField "signature" (inputJson value) values)

type ByoipPrefix =
  { resource :: Resource ByoipPrefixResource
  , advertised :: Expr Boolean
  , failureReason :: Expr String
  , id :: Expr String
  , prefix :: Expr String
  , region :: Expr String
  , signature :: Expr String
  , status :: Expr String
  , uuid :: Expr String
  }

create :: String -> Args -> Infra ByoipPrefix
create logicalName (Args values) = do
  handle <- addResource "digitalocean_byoip_prefix" logicalName values
  pure
    { resource: handle
    , advertised: resourceAttr handle [ "advertised" ]
    , failureReason: resourceAttr handle [ "failure_reason" ]
    , id: resourceAttr handle [ "id" ]
    , prefix: resourceAttr handle [ "prefix" ]
    , region: resourceAttr handle [ "region" ]
    , signature: resourceAttr handle [ "signature" ]
    , status: resourceAttr handle [ "status" ]
    , uuid: resourceAttr handle [ "uuid" ]
    }
