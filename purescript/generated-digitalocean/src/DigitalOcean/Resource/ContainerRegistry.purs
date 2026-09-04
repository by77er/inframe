module DigitalOcean.Resource.ContainerRegistry
  ( Args
  , Required
  , ContainerRegistry
  , ContainerRegistryResource
  , args
  , create
  , id
  , region
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data ContainerRegistryResource

type Required =
  { name :: Input String
  , subscriptionTierSlug :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "subscription_tier_slug" (inputJson required.subscriptionTierSlug)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (Object.insert "region" (inputJson value) values)

type ContainerRegistry =
  { resource :: Resource ContainerRegistryResource
  , createdAt :: Expr String
  , endpoint :: Expr String
  , id :: Expr String
  , name :: Expr String
  , region :: Expr String
  , serverUrl :: Expr String
  , storageUsageBytes :: Expr Number
  , subscriptionTierSlug :: Expr String
  }

create :: String -> Args -> Infra ContainerRegistry
create logicalName (Args values) = do
  handle <- addResource "digitalocean_container_registry" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , endpoint: resourceAttr handle [ "endpoint" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , region: resourceAttr handle [ "region" ]
    , serverUrl: resourceAttr handle [ "server_url" ]
    , storageUsageBytes: resourceAttr handle [ "storage_usage_bytes" ]
    , subscriptionTierSlug: resourceAttr handle [ "subscription_tier_slug" ]
    }
