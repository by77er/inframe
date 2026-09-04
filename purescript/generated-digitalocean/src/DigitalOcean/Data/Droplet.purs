module DigitalOcean.Data.Droplet
  ( Args
  , Required
  , Droplet
  , DropletDataSource
  , args
  , read
  , gpu
  , id
  , name
  , tag
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data DropletDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

gpu :: Input Boolean -> Args -> Args
gpu value (Args values) = Args (Object.insert "gpu" (inputJson value) values)

id :: Input Number -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (Object.insert "name" (inputJson value) values)

tag :: Input String -> Args -> Args
tag value (Args values) = Args (Object.insert "tag" (inputJson value) values)

type Droplet =
  { dataSource :: DataSource DropletDataSource
  , backups :: Expr Boolean
  , createdAt :: Expr String
  , disk :: Expr Number
  , gpu :: Expr Boolean
  , gpuPartitionMode :: Expr String
  , id :: Expr Number
  , image :: Expr String
  , ipv4Address :: Expr String
  , ipv4AddressPrivate :: Expr String
  , ipv6 :: Expr Boolean
  , ipv6Address :: Expr String
  , ipv6AddressPrivate :: Expr String
  , locked :: Expr Boolean
  , memory :: Expr Number
  , monitoring :: Expr Boolean
  , name :: Expr String
  , priceHourly :: Expr Number
  , priceMonthly :: Expr Number
  , privateNetworking :: Expr Boolean
  , region :: Expr String
  , size :: Expr String
  , status :: Expr String
  , tag :: Expr String
  , tags :: Expr (Array String)
  , urn :: Expr String
  , vcpus :: Expr Number
  , volumeIds :: Expr (Array String)
  , vpcUuid :: Expr String
  }

read :: String -> Args -> Infra Droplet
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_droplet" logicalName values
  pure
    { dataSource: handle
    , backups: dataSourceAttr handle [ "backups" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , disk: dataSourceAttr handle [ "disk" ]
    , gpu: dataSourceAttr handle [ "gpu" ]
    , gpuPartitionMode: dataSourceAttr handle [ "gpu_partition_mode" ]
    , id: dataSourceAttr handle [ "id" ]
    , image: dataSourceAttr handle [ "image" ]
    , ipv4Address: dataSourceAttr handle [ "ipv4_address" ]
    , ipv4AddressPrivate: dataSourceAttr handle [ "ipv4_address_private" ]
    , ipv6: dataSourceAttr handle [ "ipv6" ]
    , ipv6Address: dataSourceAttr handle [ "ipv6_address" ]
    , ipv6AddressPrivate: dataSourceAttr handle [ "ipv6_address_private" ]
    , locked: dataSourceAttr handle [ "locked" ]
    , memory: dataSourceAttr handle [ "memory" ]
    , monitoring: dataSourceAttr handle [ "monitoring" ]
    , name: dataSourceAttr handle [ "name" ]
    , priceHourly: dataSourceAttr handle [ "price_hourly" ]
    , priceMonthly: dataSourceAttr handle [ "price_monthly" ]
    , privateNetworking: dataSourceAttr handle [ "private_networking" ]
    , region: dataSourceAttr handle [ "region" ]
    , size: dataSourceAttr handle [ "size" ]
    , status: dataSourceAttr handle [ "status" ]
    , tag: dataSourceAttr handle [ "tag" ]
    , tags: dataSourceAttr handle [ "tags" ]
    , urn: dataSourceAttr handle [ "urn" ]
    , vcpus: dataSourceAttr handle [ "vcpus" ]
    , volumeIds: dataSourceAttr handle [ "volume_ids" ]
    , vpcUuid: dataSourceAttr handle [ "vpc_uuid" ]
    }
