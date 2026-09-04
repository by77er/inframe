module DigitalOcean.Data.Sizes
  ( Args
  , Required
  , Sizes
  , SizesDataSource
  , args
  , read
  , filter
  , id
  , sort
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data SizesDataSource

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

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

sort :: Input (Array ({ direction :: String, key :: String })) -> Args -> Args
sort value (Args values) = Args (Object.insert "sort" (inputJson value) values)

type Sizes =
  { dataSource :: DataSource SizesDataSource
  , id :: Expr String
  , sizes :: Expr (Array ({ available :: Boolean, disk :: Number, gpuInfo :: Array ({ count :: Number, model :: String, supportedPartitionModes :: Array String, vram :: Array ({ amount :: Number, unit :: String }) }), memory :: Number, priceHourly :: Number, priceMonthly :: Number, regions :: Array String, slug :: String, transfer :: Number, vcpus :: Number }))
  }

read :: String -> Args -> Infra Sizes
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_sizes" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , sizes: dataSourceAttr handle [ "sizes" ]
    }
