module DigitalOcean.Data.DedicatedInferenceSizes
  ( Args
  , Required
  , DedicatedInferenceSizes
  , DedicatedInferenceSizesDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data DedicatedInferenceSizesDataSource

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type DedicatedInferenceSizes =
  { dataSource :: DataSource DedicatedInferenceSizesDataSource
  , enabledRegions :: Expr (Array String)
  , id :: Expr String
  , sizes :: Expr (Array ({ cpu :: Number, currency :: String, disks :: Array ({ sizeGb :: Number, type_ :: String }), gpu :: Array ({ count :: Number, slug :: String, vramGb :: Number }), gpuSlug :: String, memory :: Number, pricePerHour :: String, regions :: Array String, sizeCategory :: Array ({ fleetName :: String, name :: String }) }))
  }

read :: String -> Args -> Infra DedicatedInferenceSizes
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_dedicated_inference_sizes" logicalName values
  pure
    { dataSource: handle
    , enabledRegions: dataSourceAttr handle [ "enabled_regions" ]
    , id: dataSourceAttr handle [ "id" ]
    , sizes: dataSourceAttr handle [ "sizes" ]
    }
