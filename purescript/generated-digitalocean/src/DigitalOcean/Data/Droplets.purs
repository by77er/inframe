module DigitalOcean.Data.Droplets
  ( Args
  , Required
  , Droplets
  , DropletsDataSource
  , args
  , read
  , filter
  , gpus
  , id
  , sort
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data DropletsDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

filter :: Input (Array ({ all :: Boolean, key :: String, matchBy :: String, values :: Array String })) -> Args -> Args
filter value (Args values) = Args (Object.insert "filter" (inputJson value) values)

gpus :: Input Boolean -> Args -> Args
gpus value (Args values) = Args (Object.insert "gpus" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

sort :: Input (Array ({ direction :: String, key :: String })) -> Args -> Args
sort value (Args values) = Args (Object.insert "sort" (inputJson value) values)

type Droplets =
  { dataSource :: DataSource DropletsDataSource
  , droplets :: Expr (Array ({ backups :: Boolean, createdAt :: String, disk :: Number, gpuPartitionMode :: String, id :: Number, image :: String, ipv4Address :: String, ipv4AddressPrivate :: String, ipv6 :: Boolean, ipv6Address :: String, ipv6AddressPrivate :: String, locked :: Boolean, memory :: Number, monitoring :: Boolean, name :: String, priceHourly :: Number, priceMonthly :: Number, privateNetworking :: Boolean, region :: String, size :: String, status :: String, tags :: Array String, urn :: String, vcpus :: Number, volumeIds :: Array String, vpcUuid :: String }))
  , gpus :: Expr Boolean
  , id :: Expr String
  }

read :: String -> Args -> Infra Droplets
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_droplets" logicalName values
  pure
    { dataSource: handle
    , droplets: dataSourceAttr handle [ "droplets" ]
    , gpus: dataSourceAttr handle [ "gpus" ]
    , id: dataSourceAttr handle [ "id" ]
    }
