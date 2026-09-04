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

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data ByoipPrefixResourcesDataSource

type Required =
  { byoipPrefixUuid :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "byoip_prefix_uuid" (inputJson required.byoipPrefixUuid)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

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
