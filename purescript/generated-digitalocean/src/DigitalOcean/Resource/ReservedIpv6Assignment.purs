module DigitalOcean.Resource.ReservedIpv6Assignment
  ( Args
  , Required
  , ReservedIpv6Assignment
  , ReservedIpv6AssignmentResource
  , args
  , create
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data ReservedIpv6AssignmentResource

type Required =
  { dropletId :: Input Number
  , ip :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "droplet_id" (inputJson required.dropletId)
  , Tuple "ip" (inputJson required.ip)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type ReservedIpv6Assignment =
  { resource :: Resource ReservedIpv6AssignmentResource
  , dropletId :: Expr Number
  , id :: Expr String
  , ip :: Expr String
  }

create :: String -> Args -> Infra ReservedIpv6Assignment
create logicalName (Args values) = do
  handle <- addResource "digitalocean_reserved_ipv6_assignment" logicalName values
  pure
    { resource: handle
    , dropletId: resourceAttr handle [ "droplet_id" ]
    , id: resourceAttr handle [ "id" ]
    , ip: resourceAttr handle [ "ip" ]
    }
