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

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data ReservedIpv6DataSource

type Required =
  { ip :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "ip" (inputJson required.ip)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

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
