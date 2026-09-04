module DigitalOcean.Data.ReservedIp
  ( Args
  , Required
  , ReservedIp
  , ReservedIpDataSource
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

data ReservedIpDataSource

type Required =
  { ipAddress :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "ip_address" (inputJson required.ipAddress)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type ReservedIp =
  { dataSource :: DataSource ReservedIpDataSource
  , dropletId :: Expr Number
  , id :: Expr String
  , ipAddress :: Expr String
  , region :: Expr String
  , urn :: Expr String
  }

read :: String -> Args -> Infra ReservedIp
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_reserved_ip" logicalName values
  pure
    { dataSource: handle
    , dropletId: dataSourceAttr handle [ "droplet_id" ]
    , id: dataSourceAttr handle [ "id" ]
    , ipAddress: dataSourceAttr handle [ "ip_address" ]
    , region: dataSourceAttr handle [ "region" ]
    , urn: dataSourceAttr handle [ "urn" ]
    }
