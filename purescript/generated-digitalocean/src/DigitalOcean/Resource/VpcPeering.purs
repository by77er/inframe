module DigitalOcean.Resource.VpcPeering
  ( Args
  , Required
  , VpcPeering
  , VpcPeeringResource
  , args
  , create
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsCreate
  , timeoutsDelete
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data VpcPeeringResource

newtype Timeouts = Timeouts InputObject

type TimeoutsRequired =
  {
  }

timeoutsArgs :: TimeoutsRequired -> Timeouts
timeoutsArgs _ = Timeouts (inputObject
  [
  ])

timeoutsCreate :: Input String -> Timeouts -> Timeouts
timeoutsCreate value (Timeouts values) = Timeouts (insertInputField "create" (inputJson value) values)

timeoutsDelete :: Input String -> Timeouts -> Timeouts
timeoutsDelete value (Timeouts values) = Timeouts (insertInputField "delete" (inputJson value) values)

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  { name :: Input String
  , vpcIds :: Input (Array String)
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "vpc_ids" (inputJson required.vpcIds)
  ])

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

type VpcPeering =
  { resource :: Resource VpcPeeringResource
  , createdAt :: Expr String
  , id :: Expr String
  , name :: Expr String
  , status :: Expr String
  , vpcIds :: Expr (Array String)
  }

create :: String -> Args -> Infra VpcPeering
create logicalName (Args values) = do
  handle <- addResource "digitalocean_vpc_peering" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , status: resourceAttr handle [ "status" ]
    , vpcIds: resourceAttr handle [ "vpc_ids" ]
    }
