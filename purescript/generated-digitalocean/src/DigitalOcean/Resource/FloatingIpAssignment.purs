module DigitalOcean.Resource.FloatingIpAssignment
  ( Args
  , Required
  , FloatingIpAssignment
  , FloatingIpAssignmentResource
  , args
  , create
  , id
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data FloatingIpAssignmentResource

type Required =
  { dropletId :: Input Number
  , ipAddress :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "droplet_id" (inputJson required.dropletId)
  , Tuple "ip_address" (inputJson required.ipAddress)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type FloatingIpAssignment =
  { resource :: Resource FloatingIpAssignmentResource
  , dropletId :: Expr Number
  , id :: Expr String
  , ipAddress :: Expr String
  }

create :: String -> Args -> Infra FloatingIpAssignment
create logicalName (Args values) = do
  handle <- addResource "digitalocean_floating_ip_assignment" logicalName values
  pure
    { resource: handle
    , dropletId: resourceAttr handle [ "droplet_id" ]
    , id: resourceAttr handle [ "id" ]
    , ipAddress: resourceAttr handle [ "ip_address" ]
    }
