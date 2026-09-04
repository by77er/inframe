module DigitalOcean.Data.ReservedIpv6
  ( Args
  , Required
  , ReservedIpv6
  , ReservedIpv6DataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data ReservedIpv6DataSource

type Required =
  { ip :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "ip" (inputJson required.ip)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type ReservedIpv6 =
  { dataSource :: DataSource ReservedIpv6DataSource
  , dropletId :: Expr Number
  , id :: Expr String
  , ip :: Expr String
  , regionSlug :: Expr String
  , urn :: Expr String
  }

read :: String -> Args -> Infra ReservedIpv6
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_reserved_ipv6" logicalName values
  pure
    { dataSource: handle
    , dropletId: dataSourceAttr handle [ "droplet_id" ]
    , id: dataSourceAttr handle [ "id" ]
    , ip: dataSourceAttr handle [ "ip" ]
    , regionSlug: dataSourceAttr handle [ "region_slug" ]
    , urn: dataSourceAttr handle [ "urn" ]
    }
