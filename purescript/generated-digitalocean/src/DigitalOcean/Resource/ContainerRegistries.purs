module DigitalOcean.Resource.ContainerRegistries
  ( Args
  , Required
  , ContainerRegistries
  , ContainerRegistriesResource
  , args
  , create
  , id
  , region
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data ContainerRegistriesResource

type Required =
  { name :: Input String
  , subscriptionTierSlug :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "subscription_tier_slug" (inputJson required.subscriptionTierSlug)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (insertInputField "region" (inputJson value) values)

type ContainerRegistries =
  { resource :: Resource ContainerRegistriesResource
  , createdAt :: Expr String
  , endpoint :: Expr String
  , id :: Expr String
  , name :: Expr String
  , region :: Expr String
  , serverUrl :: Expr String
  , storageUsageBytes :: Expr Number
  , subscriptionTierSlug :: Expr String
  }

create :: String -> Args -> Infra ContainerRegistries
create logicalName (Args values) = do
  handle <- addResource "digitalocean_container_registries" logicalName values
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
