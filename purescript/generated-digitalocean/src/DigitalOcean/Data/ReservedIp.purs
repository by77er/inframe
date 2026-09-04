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

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data ReservedIpDataSource

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
