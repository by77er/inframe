module DigitalOcean.Data.ByoipPrefixResources
  ( Args
  , Required
  , ByoipPrefixResources
  , ByoipPrefixResourcesDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data ByoipPrefixResourcesDataSource

type Required =
  { byoipPrefixUuid :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "byoip_prefix_uuid" (inputJson required.byoipPrefixUuid)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type ByoipPrefixResources =
  { dataSource :: DataSource ByoipPrefixResourcesDataSource
  , addresses :: Expr (Array ({ assignedAt :: String, id :: Number, ipAddress :: String, region :: String }))
  , byoipPrefixUuid :: Expr String
  , id :: Expr String
  }

read :: String -> Args -> Infra ByoipPrefixResources
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_byoip_prefix_resources" logicalName values
  pure
    { dataSource: handle
    , addresses: dataSourceAttr handle [ "addresses" ]
    , byoipPrefixUuid: dataSourceAttr handle [ "byoip_prefix_uuid" ]
    , id: dataSourceAttr handle [ "id" ]
    }
