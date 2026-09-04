module DigitalOcean.Data.DropletAutoscale
  ( Args
  , Required
  , DropletAutoscale
  , DropletAutoscaleDataSource
  , args
  , read
  , id
  , name
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data DropletAutoscaleDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (Object.insert "name" (inputJson value) values)

type DropletAutoscale =
  { dataSource :: DataSource DropletAutoscaleDataSource
  , config :: Expr (Array ({ cooldownMinutes :: Number, maxInstances :: Number, minInstances :: Number, targetCpuUtilization :: Number, targetMemoryUtilization :: Number, targetNumberInstances :: Number }))
  , createdAt :: Expr String
  , currentUtilization :: Expr (Array ({ cpu :: Number, memory :: Number }))
  , dropletTemplate :: Expr (Array ({ image :: String, ipv6 :: Boolean, projectId :: String, publicNetworking :: Boolean, region :: String, size :: String, sshKeys :: Array String, tags :: Array String, userData :: String, vpcUuid :: String, withDropletAgent :: Boolean }))
  , id :: Expr String
  , name :: Expr String
  , status :: Expr String
  , updatedAt :: Expr String
  }

read :: String -> Args -> Infra DropletAutoscale
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_droplet_autoscale" logicalName values
  pure
    { dataSource: handle
    , config: dataSourceAttr handle [ "config" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , currentUtilization: dataSourceAttr handle [ "current_utilization" ]
    , dropletTemplate: dataSourceAttr handle [ "droplet_template" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , status: dataSourceAttr handle [ "status" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    }
