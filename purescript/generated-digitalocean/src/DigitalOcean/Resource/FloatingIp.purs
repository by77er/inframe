module DigitalOcean.Resource.FloatingIp
  ( Args
  , Required
  , FloatingIp
  , FloatingIpResource
  , args
  , create
  , dropletId
  , id
  , ipAddress
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data FloatingIpResource

type Required =
  { region :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "region" (inputJson required.region)
  ])

dropletId :: Input Number -> Args -> Args
dropletId value (Args values) = Args (Object.insert "droplet_id" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

ipAddress :: Input String -> Args -> Args
ipAddress value (Args values) = Args (Object.insert "ip_address" (inputJson value) values)

type FloatingIp =
  { resource :: Resource FloatingIpResource
  , dropletId :: Expr Number
  , id :: Expr String
  , ipAddress :: Expr String
  , region :: Expr String
  , urn :: Expr String
  }

create :: String -> Args -> Infra FloatingIp
create logicalName (Args values) = do
  handle <- addResource "digitalocean_floating_ip" logicalName values
  pure
    { resource: handle
    , dropletId: resourceAttr handle [ "droplet_id" ]
    , id: resourceAttr handle [ "id" ]
    , ipAddress: resourceAttr handle [ "ip_address" ]
    , region: resourceAttr handle [ "region" ]
    , urn: resourceAttr handle [ "urn" ]
    }
