module DigitalOcean.Data.ContainerRegistry
  ( Args
  , Required
  , ContainerRegistry
  , ContainerRegistryDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data ContainerRegistryDataSource

type Required =
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type ContainerRegistry =
  { dataSource :: DataSource ContainerRegistryDataSource
  , createdAt :: Expr String
  , endpoint :: Expr String
  , id :: Expr String
  , name :: Expr String
  , region :: Expr String
  , serverUrl :: Expr String
  , storageUsageBytes :: Expr Number
  , subscriptionTierSlug :: Expr String
  }

read :: String -> Args -> Infra ContainerRegistry
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_container_registry" logicalName values
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
