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

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data DedicatedInferenceSizesDataSource

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
