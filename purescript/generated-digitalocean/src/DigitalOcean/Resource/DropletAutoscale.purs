module DigitalOcean.Resource.DropletAutoscale
  ( Args
  , Required
  , DropletAutoscale
  , DropletAutoscaleResource
  , args
  , create
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DropletAutoscaleResource

type Required =
  { config :: Input (Array ({ cooldownMinutes :: Number, maxInstances :: Number, minInstances :: Number, targetCpuUtilization :: Number, targetMemoryUtilization :: Number, targetNumberInstances :: Number }))
  , dropletTemplate :: Input (Array ({ image :: String, ipv6 :: Boolean, projectId :: String, publicNetworking :: Boolean, region :: String, size :: String, sshKeys :: Array String, tags :: Array String, userData :: String, vpcUuid :: String, withDropletAgent :: Boolean }))
  , name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "config" (inputJson required.config)
  , Tuple "droplet_template" (inputJson required.dropletTemplate)
  , Tuple "name" (inputJson required.name)
  ])

type DropletAutoscale =
  { resource :: Resource DropletAutoscaleResource
  , createdAt :: Expr String
  , currentUtilization :: Expr (Array ({ cpu :: Number, memory :: Number }))
  , id :: Expr String
  , name :: Expr String
  , status :: Expr String
  , updatedAt :: Expr String
  }

create :: String -> Args -> Infra DropletAutoscale
create logicalName (Args values) = do
  handle <- addResource "digitalocean_droplet_autoscale" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , currentUtilization: resourceAttr handle [ "current_utilization" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , status: resourceAttr handle [ "status" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    }
