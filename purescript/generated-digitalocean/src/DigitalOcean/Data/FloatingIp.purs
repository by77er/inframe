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

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data FloatingIpDataSource

type Required =
  { ipAddress :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "ip_address" (inputJson required.ipAddress)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

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
