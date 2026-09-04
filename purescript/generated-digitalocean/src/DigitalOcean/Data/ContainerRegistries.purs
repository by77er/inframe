module DigitalOcean.Data.ContainerRegistries
  ( Args
  , Required
  , ContainerRegistries
  , ContainerRegistriesDataSource
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

data ContainerRegistriesDataSource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type ContainerRegistries =
  { dataSource :: DataSource ContainerRegistriesDataSource
  , createdAt :: Expr String
  , endpoint :: Expr String
  , id :: Expr String
  , name :: Expr String
  , region :: Expr String
  , serverUrl :: Expr String
  , storageUsageBytes :: Expr Number
  , subscriptionTierSlug :: Expr String
  }

read :: String -> Args -> Infra ContainerRegistries
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_container_registries" logicalName values
  pure
    { dataSource: handle
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , endpoint: dataSourceAttr handle [ "endpoint" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , region: dataSourceAttr handle [ "region" ]
    , serverUrl: dataSourceAttr handle [ "server_url" ]
    , storageUsageBytes: dataSourceAttr handle [ "storage_usage_bytes" ]
    , subscriptionTierSlug: dataSourceAttr handle [ "subscription_tier_slug" ]
    }
