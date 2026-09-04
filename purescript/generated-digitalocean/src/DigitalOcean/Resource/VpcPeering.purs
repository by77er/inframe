module DigitalOcean.Resource.VpcPeering
  ( Args
  , Required
  , VpcPeering
  , VpcPeeringResource
  , args
  , create
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data VpcPeeringResource

type Required =
  { name :: Input String
  , vpcIds :: Input (Array String)
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "vpc_ids" (inputJson required.vpcIds)
  ])

timeouts :: Input ({ create :: String, delete :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

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
