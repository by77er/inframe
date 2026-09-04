module DigitalOcean.Data.Droplets
  ( Args
  , Required
  , Droplets
  , DropletsDataSource
  , args
  , read
  , Filter
  , FilterRequired
  , filterArgs
  , filterAll
  , filterMatchBy
  , Sort
  , SortRequired
  , sortArgs
  , sortDirection
  , filter
  , gpus
  , id
  , sort
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, DataSource, dataSourceAttr)

data DropletsDataSource

newtype Filter = Filter InputObject

type FilterRequired =
  { key :: Input String
  , values :: Input (Array String)
  }

filterArgs :: FilterRequired -> Filter
filterArgs required = Filter (inputObject
  [ Tuple "key" (inputJson required.key)
  , Tuple "values" (inputJson required.values)
  ])

filterAll :: Input Boolean -> Filter -> Filter
filterAll value (Filter values) = Filter (insertInputField "all" (inputJson value) values)

filterMatchBy :: Input String -> Filter -> Filter
filterMatchBy value (Filter values) = Filter (insertInputField "match_by" (inputJson value) values)

filterJson :: Filter -> Json
filterJson (Filter values) = inputObjectJson values

newtype Sort = Sort InputObject

type SortRequired =
  { key :: Input String
  }

sortArgs :: SortRequired -> Sort
sortArgs required = Sort (inputObject
  [ Tuple "key" (inputJson required.key)
  ])

sortDirection :: Input String -> Sort -> Sort
sortDirection value (Sort values) = Sort (insertInputField "direction" (inputJson value) values)

sortJson :: Sort -> Json
sortJson (Sort values) = inputObjectJson values

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

filter :: Array Filter -> Args -> Args
filter value (Args values) = Args (insertInputField "filter" (arrayExprJson (map filterJson value)) values)

gpus :: Input Boolean -> Args -> Args
gpus value (Args values) = Args (insertInputField "gpus" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

sort :: Array Sort -> Args -> Args
sort value (Args values) = Args (insertInputField "sort" (arrayExprJson (map sortJson value)) values)

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
