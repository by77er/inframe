module DigitalOcean.Data.FloatingIp
  ( Args
  , Required
  , FloatingIp
  , FloatingIpDataSource
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

data FloatingIpDataSource

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

type FloatingIp =
  { dataSource :: DataSource FloatingIpDataSource
  , dropletId :: Expr Number
  , id :: Expr String
  , ipAddress :: Expr String
  , region :: Expr String
  , urn :: Expr String
  }

read :: String -> Args -> Infra FloatingIp
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_floating_ip" logicalName values
  pure
    { dataSource: handle
    , dropletId: dataSourceAttr handle [ "droplet_id" ]
    , id: dataSourceAttr handle [ "id" ]
    , ipAddress: dataSourceAttr handle [ "ip_address" ]
    , region: dataSourceAttr handle [ "region" ]
    , urn: dataSourceAttr handle [ "urn" ]
    }
