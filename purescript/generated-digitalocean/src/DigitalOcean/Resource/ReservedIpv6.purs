module DigitalOcean.Resource.ReservedIpv6
  ( Args
  , Required
  , ReservedIpv6
  , ReservedIpv6Resource
  , args
  , create
  , dropletId
  , id
  , ip
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data ReservedIpv6Resource

type Required =
  { regionSlug :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "region_slug" (inputJson required.regionSlug)
  ])

dropletId :: Input Number -> Args -> Args
dropletId value (Args values) = Args (insertInputField "droplet_id" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

ip :: Input String -> Args -> Args
ip value (Args values) = Args (insertInputField "ip" (inputJson value) values)

type ReservedIpv6 =
  { resource :: Resource ReservedIpv6Resource
  , dropletId :: Expr Number
  , id :: Expr String
  , ip :: Expr String
  , regionSlug :: Expr String
  , urn :: Expr String
  }

create :: String -> Args -> Infra ReservedIpv6
create logicalName (Args values) = do
  handle <- addResource "digitalocean_reserved_ipv6" logicalName values
  pure
    { resource: handle
    , dropletId: resourceAttr handle [ "droplet_id" ]
    , id: resourceAttr handle [ "id" ]
    , ip: resourceAttr handle [ "ip" ]
    , regionSlug: resourceAttr handle [ "region_slug" ]
    , urn: resourceAttr handle [ "urn" ]
    }
