module DigitalOcean.Data.GradientaiRegions
  ( Args
  , Required
  , GradientaiRegions
  , GradientaiRegionsDataSource
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

data GradientaiRegionsDataSource

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

type GradientaiRegions =
  { dataSource :: DataSource GradientaiRegionsDataSource
  , id :: Expr String
  , regions :: Expr (Array ({ inferenceUrl :: String, region :: String, servesBatch :: Boolean, servesInference :: Boolean, streamInferenceUrl :: String }))
  }

read :: String -> Args -> Infra GradientaiRegions
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_regions" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , regions: dataSourceAttr handle [ "regions" ]
    }
